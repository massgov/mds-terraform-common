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
  DescribeImagesCommand,
  ECR,
  FindingSeverity,
  ScanNotFoundException,
  ScanStatus,
  StartImageScanCommand,
  waitUntilImageScanComplete,
} from "@aws-sdk/client-ecr";
import { isFindingIgnored, isClusterSnoozed } from "./ignore";
import { PublishCommand, SNSClient } from "@aws-sdk/client-sns";
import assert from "assert";

// Change: cluster is now a string or string[]
type Input = {
  cluster: string | string[];
};

type Env = {
  ERROR_TOPIC_ARN: string;
  ALERT_SEVERITY_LEVEL: Severity;
  AWS_ACCOUNT_ID: string;
  AWS_REGION: string;
};

const defaultLogger = pino({ level: process.env.LOG_LEVEL ?? "debug" });

const ecr = new ECR();
const ecs = new ECS();
const snsClient = new SNSClient();

const getEnv = (): Env => {
  const { ERROR_TOPIC_ARN, ALERT_SEVERITY_LEVEL, AWS_ACCOUNT_ID, AWS_REGION } =
    process.env;

  assert(
    typeof ERROR_TOPIC_ARN === "string",
    "'ERROR_TOPIC_ARN' missing from environment",
  );

  assert(
    typeof ALERT_SEVERITY_LEVEL === "string",
    "'ALERT_SEVERITY_LEVEL' missing from environment",
  );

  assert(
    typeof AWS_ACCOUNT_ID === "string",
    "'AWS_ACCOUNT_ID' missing from environment",
  );

  assert(
    typeof AWS_REGION === "string",
    "'AWS_REGION' missing from environment",
  );

  const severity = Severity[ALERT_SEVERITY_LEVEL as keyof typeof Severity];

  assert(severity !== undefined, "Invalid 'ALERT_SEVERITY_LEVEL'");

  return {
    ERROR_TOPIC_ARN,
    ALERT_SEVERITY_LEVEL: severity,
    AWS_ACCOUNT_ID,
    AWS_REGION,
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
    imageTag?: string;
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

  // if there aren’t any task ARNs, bail out early instead of calling DescribeTasks with []
  // which would throw an error
  // https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DescribeTasks.html
  if (!clusterTasks.taskArns || clusterTasks.taskArns.length === 0) {
    logger.info(`No tasks found for ECS cluster '${cluster}', skipping image collection.`);
    return new Map<string, Set<string>>();
  }

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
    logger.error(tasks.failures);
    throw new Error(
      `Encountered failures when describing tasks for ${cluster}`,
    );
  }

  if (!tasks.tasks) {
    throw new Error(`No tasks found for cluster ${cluster}`);
  }

  for (const t of tasks.tasks) {
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

const parseImageURI = async (
  ecrClient: ECR,
  logger: pino.Logger,
  uri: string,
): Promise<ImageDescriptor> => {
  const match = uri.match(
    /\/([A-Za-z0-9_-]+).(sha256:[A-Fa-f0-9]{64}|[A-Fa-f0-9]{40})$/,
  );

  if (
    match === null ||
    typeof match[1] !== "string" ||
    typeof match[2] !== "string"
  ) {
    throw new Error("Unable to parse ECR Image URI.");
  }
  const repo = match[1];
  const imageID = match[2];

  // 64 character hash + 'sha256: = 71'
  if (imageID.length === 71) {
    logger.debug(`We got a digest in the image URI: ${imageID}`);

    return {
      repositoryName: repo,
      imageId: {
        imageDigest: imageID,
      },
    };
  } else if (imageID.length === 40) {
    logger.debug(`We got a tag in the image URI: ${imageID}`);

    const input = {
      repositoryName: repo,
      imageIds: [
        {
          imageTag: imageID,
        },
      ],
    };

    const details = await ecrClient.send(new DescribeImagesCommand(input));

    assert(
      details.imageDetails !== undefined &&
      details.imageDetails[0]?.imageDigest,
      `DescribeImagesCommand failed for repo ${repo} on image ${imageID}`,
    );

    return {
      repositoryName: repo,
      imageId: {
        imageDigest: details.imageDetails[0].imageDigest,
        imageTag: imageID,
      },
    };
  } else {
    throw new Error("Something went wrong with our regex");
  }
};

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
  cluster: string,
  request: DescribeImageScanFindingsRequest,
  alertLevel: Severity,
  logger: pino.Logger,
): Promise<boolean> => {
  logger.debug(
    `Checking scan results for repo '${request.repositoryName}' digest '${request?.imageId?.imageDigest}'`,
  );

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
        return false;
      }

      if (await isFindingIgnored(finding)) {
        logger.debug(`Ignoring vulnerability '${finding.name}'`);
      } else if (await isClusterSnoozed(cluster)) {
        logger.debug(`Cluster '${cluster}' has been snoozed. Skipping alert`);
      } else {
        logger.debug(`Found open vulnerability '${finding.name}'.`);
        return true;
      }
    }

    request.nextToken = findings.nextToken;
  } while (request.nextToken);

  return false;
};

function formatResults(
  cluster: string,
  alertResults: Map<string, AlertResults>,
): string {
  const now = new Date();
  const { AWS_ACCOUNT_ID, AWS_REGION } = getEnv();

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
    const scanUrl = `https://${AWS_REGION}.console.aws.amazon.com/ecr/repositories/private/${AWS_ACCOUNT_ID}/${value.image.repositoryName}/_/image/${value.image.imageId.imageDigest}/details?region=${AWS_REGION}`;
    lines.push(
      `    The full results of the scan can be found here: ${scanUrl}`,
    );
    lines.push("");
  }

  return lines.join("\n");
}

// Handler: only process clusters from input, not all clusters in the account!
const handler: Handler<Input, void> = async (
  event,
  context,
  callback,
): Promise<void> => {
  const logger = defaultLogger.child({
    functionArn: context.invokedFunctionArn,
    awsRequestId: context.awsRequestId,
  });
  const { ERROR_TOPIC_ARN, ALERT_SEVERITY_LEVEL } = getEnv();

  const now = new Date();

  const clusters = Array.isArray(event.cluster) ? event.cluster : [event.cluster];

  for (const cluster of clusters) {
    const images = await getContainerImages(ecs, cluster, logger);
    if (images.size === 0) {
      continue;
    }

    const scanResults = new Map();

    for (const imageURI of images.keys()) {
      const imageDescriptor = await parseImageURI(ecr, logger, imageURI);
      const img = await updateImageScan(ecr, imageDescriptor, now, logger);
      scanResults.set(imageURI, img);
    }

    const alertResults = new Map();

    for (const imageURI of scanResults.keys()) {
      const imageDescriptor = await parseImageURI(ecr, logger, imageURI);
      let result = scanResults.get(imageURI);

      if (result.imageScanStatus?.status !== ScanStatus.COMPLETE) {
        result = await waitUntilImageScanComplete(
          { client: ecr, maxWaitTime: 600 },
          imageDescriptor,
        );
      }

      let needsAlert = await scanNeedsAlert(
        ecr,
        cluster,
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
  }
};

export { handler };