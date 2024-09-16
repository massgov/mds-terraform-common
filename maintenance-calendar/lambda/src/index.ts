import pino from "pino";
import { Handler } from "aws-lambda";
import {
  DescribeTasksCommand,
  ECS,
  ListTasksCommand,
} from "@aws-sdk/client-ecs";
import {
  DescribeImageScanFindingsCommand,
  DescribeImageScanFindingsRequest,
  DescribeImageScanFindingsResponse,
  ECR,
  FindingSeverity,
  ScanNotFoundException,
  ScanStatus,
  StartImageScanCommand,
  waitUntilImageScanComplete,
} from "@aws-sdk/client-ecr";
import { isFindingIgnored } from "./ignore";
import { PublishCommand, SNSClient } from "@aws-sdk/client-sns";
import assert from "assert";

type Input = {
  cluster: string;
};

type Env = {
  ERROR_TOPIC_ARN: string;
  ALERT_SEVERITY_LEVEL: Severity;
};

const defaultLogger = pino({ level: process.env.LOG_LEVEL ?? "debug" });

const ecr = new ECR();
const ecs = new ECS();
const snsClient = new SNSClient();

const getEnv = (): Env => {
  const { ERROR_TOPIC_ARN, ALERT_SEVERITY_LEVEL } = process.env;

  assert(
    typeof ERROR_TOPIC_ARN === "string",
    "'ERROR_TOPIC_ARN' missing from environment",
  );

  assert(
    typeof ALERT_SEVERITY_LEVEL === "string",
    "'ALERT_SEVERITY_LEVEL' missing from environment",
  );

  const severity = Severity[ALERT_SEVERITY_LEVEL as keyof typeof Severity];

  assert(severity !== undefined, "Invalid 'ALERT_SEVERITY_LEVEL'");

  return {
    ERROR_TOPIC_ARN,
    ALERT_SEVERITY_LEVEL: severity,
  };
};

enum Severity {
  UNDEFINED,
  INFORMATIONAL,
  LOW,
  MEDIUM,
  HIGH,
  CRITICAL,
}

type ImageDescriptor = {
  repositoryName: string;
  imageId: {
    imageDigest: string;
  };
};

type ImageTaskInfo = Map<string, Set<string>>;

type AlertResults = {
  image: ImageDescriptor;
  results: DescribeImageScanFindingsResponse;
  tasks: Set<string>;
};

const getContainerImages = async (
  ecsClient: ECS,
  cluster: string,
  logger: pino.Logger,
): Promise<ImageTaskInfo> => {
  const clusterTasks = await ecsClient.send(
    new ListTasksCommand({ cluster: cluster }),
  );

  if (clusterTasks.nextToken) {
    // We shouldn't ever hit this, but if we do, this error will let us know
    // that we need to make this function iterate over multiple pages.
    throw new Error("Doesn't support clusters with >100 tasks.");
  }

  const tasks = await ecsClient.send(
    new DescribeTasksCommand({
      cluster: cluster,
      tasks: clusterTasks.taskArns,
    }),
  );

  const images = new Map();

  if (tasks.failures && tasks.failures.length > 0) {
    // I am not sure in what cases this would populated - the only thing I can
    // think of is if maybe permissions only allowed describing specific tasks,
    // or maybe if a task arn provided was invalid.
    logger.error(tasks.failures);
    throw new Error(
      `Encountered failures when describing tasks for ${cluster}`,
    );
  }

  if (!tasks.tasks) {
    throw new Error(`No tasks found for cluster ${cluster}`);
  }

  for (const t of tasks.tasks) {
    // I am not sure if this is necessarily an error. There may be legitimate
    // cases where we have tasks with no containers, but right now I can't
    // think of any.
    assert(t.containers, `No containers found for task ${t.taskDefinitionArn}`);

    for (const c of t.containers) {
      if (!images.has(c.image)) {
        images.set(c.image, new Set());
      }

      logger.debug(
        `Found image '${c.image}' for container '${c.containerArn}'`,
      );

      images.get(c.image).add(t.taskDefinitionArn);
    }
  }

  return images;
};

function parseImageURI(uri: string): ImageDescriptor {
  const match = uri.match(/\/([A-Za-z0-9_-]+)@(sha256:[A-Fa-f0-9]+)$/);

  if (
    match === null ||
    typeof match[1] !== "string" ||
    typeof match[2] !== "string"
  ) {
    // If match is an array, 1 and 2 will always be strings, but typescript
    // doesn't know that.
    throw new Error("Unable to parse ECR Image URI.");
  }

  return {
    repositoryName: match[1],
    imageId: {
      imageDigest: match[2],
    },
  };
}

// See if a scan exists for the given image. If a scan doesn't exist, or the
// scan is more than 1 day old, a new scan is started.
const updateImageScan = async (
  ecrClient: ECR,
  image: ImageDescriptor,
  now: Date,
  logger: pino.Logger,
): Promise<DescribeImageScanFindingsResponse> => {
  let findings = null;

  logger.debug(
    `Looking for existing scan for 'repository ${image.repositoryName}' digest '${image.imageId.imageDigest}'`,
  );

  try {
    findings = await ecrClient.send(
      new DescribeImageScanFindingsCommand(image),
    );
  } catch (e) {
    // We can ignore ScanNotFound. We're just going to do the scan now.
    if (e instanceof ScanNotFoundException) {
      logger.debug(`No existing scan found.`);
    } else {
      throw e;
    }
  }

  if (findings) {
    if (!findings.imageScanStatus?.status) {
      throw new Error("Expected image scan status to be set.");
    } else if (findings.imageScanStatus?.status === ScanStatus.COMPLETE) {
      if (!findings.imageScanFindings?.imageScanCompletedAt) {
        throw new Error(
          "Expected completed scan to have completion timestamp.",
        );
      }

      const scanCompleted =
        findings.imageScanFindings.imageScanCompletedAt.getTime();
      logger.debug(
        `Existing scan is ${(now.getTime() - scanCompleted) / 1000} seconds old`,
      );

      // Scan is less than 24 hours old. If we try to scan again, it will throw
      // an error.
      if (now.getTime() - scanCompleted < 86400000) {
        return findings;
      }
    }
  }

  logger.debug(
    `Starting new scan for repository '${image.repositoryName}' digest '${image.imageId.imageDigest}'`,
  );

  return await ecrClient.send(new StartImageScanCommand(image));
};

const scanNeedsAlert = async (
  ecrClient: ECR,
  request: DescribeImageScanFindingsRequest,
  alertLevel: Severity,
  logger: pino.Logger,
): Promise<boolean> => {
  logger.debug(
    `Checking scan results for repo '${request.repositoryName}' digest '${request?.imageId?.imageDigest}'`,
  );

  // We may need to scan multiple pages of results.
  do {
    let findings = await ecrClient.send(
      new DescribeImageScanFindingsCommand(request),
    );

    if (findings?.imageScanFindings?.findings === undefined) {
      throw new Error(
        "Expected imageScanFindings.findings to be set, even if empty",
      );
    }

    for (const finding of findings.imageScanFindings.findings) {
      if (finding.severity === undefined) {
        throw new Error("Expected finding.severity to be set.");
      }

      if (Severity[finding.severity] < alertLevel) {
        // We've made it through all the findings >= our alert level.
        return false;
      }

      if (isFindingIgnored(finding)) {
        logger.debug(`Ignoring vulnerability '${finding.name}'`);
      } else {
        // There was a vulnerability >= our alert level that was not ignored.
        logger.debug(`Found open vulnerability '${finding.name}'.`);

        return true;
      }
    }

    // Continue on to the next page.
    request.nextToken = findings.nextToken;
  } while (request.nextToken);

  // We didn't find any vulnerabilities that would require an alert.
  return false;
};

function formatResults(
  cluster: string,
  alertResults: Map<string, AlertResults>,
): string {
  const now = new Date();

  const sortedLevels = [
    FindingSeverity.CRITICAL,
    FindingSeverity.HIGH,
    FindingSeverity.MEDIUM,
    FindingSeverity.LOW,
    FindingSeverity.INFORMATIONAL,
    FindingSeverity.UNDEFINED,
  ];

  const lines = [
    `An automated ECR scan on images currently in use by the ECS Cluster '${cluster}' was performed on ${now.toString()}.`,
    "",
    "The following images contained open vulnerabilities:",
  ];

  for (let [key, value] of alertResults) {
    lines.push(`  - ${key}`);

    if (value.results.imageScanFindings?.findingSeverityCounts) {
      const counts = value.results.imageScanFindings.findingSeverityCounts;

      lines.push("");
      lines.push(`    Number of findings, by severity category:`);

      for (let level of sortedLevels) {
        lines.push(`      - ${level}: ${counts[level]}`);
      }
    }

    lines.push("");
    lines.push(`    This image is used by the following tasks:`);

    for (const task of value.tasks) {
      lines.push(`      - ${task}`);
    }

    lines.push("");
    const scanUrl = `https://us-east-1.console.aws.amazon.com/ecr/repositories/private/786775234217/${value.image.repositoryName}/_/image/${value.image.imageId.imageDigest}/scan-results?region=us-east-1`;
    lines.push(
      `    The full results of the scan can be found here: ${scanUrl}`,
    );
    lines.push("");
  }

  return lines.join("\n");
}

const handler: Handler<Input, void> = async (
  event,
  context,
  callback,
): Promise<void> => {
  const cluster = event.cluster;

  const logger = defaultLogger.child({
    functionArn: context.invokedFunctionArn,
    awsRequestId: context.awsRequestId,
  });
  const { ERROR_TOPIC_ARN, ALERT_SEVERITY_LEVEL } = getEnv();

  const now = new Date();
  const alertLevel = ALERT_SEVERITY_LEVEL;
  const images = await getContainerImages(ecs, cluster, logger);

  const scanResults = new Map();

  // Request all scans before waiting for any of them. These can take a
  // few minutes to run.
  for (const imageURI of images.keys()) {
    const imageDescriptor = parseImageURI(imageURI);
    const img = await updateImageScan(ecr, imageDescriptor, now, logger);
    scanResults.set(imageURI, img);
  }

  const alertResults = new Map();

  for (const imageURI of scanResults.keys()) {
    const imageDescriptor = parseImageURI(imageURI);
    let result = scanResults.get(imageURI);

    if (result.imageScanStatus?.status !== ScanStatus.COMPLETE) {
      result = await waitUntilImageScanComplete(
        { client: ecr, maxWaitTime: 300 },
        imageDescriptor,
      );
    }

    let needsAlert = await scanNeedsAlert(
      ecr,
      imageDescriptor,
      ALERT_SEVERITY_LEVEL,
      logger,
    );

    if (needsAlert) {
      alertResults.set(imageURI, {
        image: imageDescriptor,
        results: result,
        tasks: images.get(imageURI),
      });
    }
  }

  if (alertResults.size > 0) {
    logger.info(formatResults(cluster, alertResults));
    await snsClient.send(
      new PublishCommand({
        TopicArn: ERROR_TOPIC_ARN,
        Message: formatResults(cluster, alertResults),
      }),
    );
  }

  logger.info(
    `Completed scan of cluster '${cluster}' - ${images.size} images scanned, ${alertResults.size} contained vulnerabilities.`,
  );
};

export { handler };
