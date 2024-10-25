// There are some vulnerabilities that, from the descriptions, clearly do not
// apply to us. If we don't do something about these, we would trigger alerts
// every day for every cluster we scan. In these cases, we can add the
// vulnerability info to parameter store so that it will be ignored by the scan.
//
// We can add the cluster name and a timestamp to another parameter to temporarily
// snooze _all_ alerts on that cluster. Valid for timestamp + seven days.
// Intended for cases where a vulnerability is patched but deployment is delayed

import { Attribute, ImageScanFinding } from "@aws-sdk/client-ecr";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import assert from "assert";
import pino from "pino";

const logger = pino({ level: process.env.LOG_LEVEL ?? "debug" });
const ssmClient = new SSMClient();

type IgnoreSpec = {
  name: string;
  packageName: string;
  packageVersion?: Array<string>;
};

type SnoozeList = {
  cluster: string;
  date: string;
};

assert(process.env.IGNORE_SPECS, "Ignore spec ARN is required");
assert(process.env.SNOOZED_CLUSTERS, "Snoozed cluster ARN is required");
const ignoreSpecARN = process.env.IGNORE_SPECS;
const snoozedClustersARN = process.env.SNOOZED_CLUSTERS;

const ignoreSpecs = async (arn: string): Promise<IgnoreSpec[]> => {
  const getParameterResult = await ssmClient.send(
    new GetParameterCommand({
      Name: arn,
      WithDecryption: true,
    }),
  );

  assert(
    getParameterResult?.Parameter?.Value,
    "Failed to fetch ignore list from Parameter Store",
  );
  return JSON.parse(getParameterResult.Parameter.Value) as Array<IgnoreSpec>;
};

function attributeMatch(
  attrs: Array<Attribute>,
  key: string,
  value: Exclude<IgnoreSpec[keyof IgnoreSpec], undefined>,
): boolean {
  for (const attr of attrs) {
    if (attr.key === key) {
      return Array.isArray(value)
        ? value.some((v) => v === attr.value)
        : value === attr.value;
    }
  }
  return false;
}

function isFindingIgnoredBySpec(
  finding: ImageScanFinding,
  spec: IgnoreSpec,
): boolean {
  if (finding?.name !== spec.name) {
    return false;
  }

  if (!finding.attributes) {
    return false;
  }

  if (!attributeMatch(finding.attributes, "package_name", spec.packageName)) {
    return false;
  }

  if (
    spec.packageVersion &&
    !attributeMatch(finding.attributes, "package_version", spec.packageVersion)
  ) {
    return false;
  }

  return true;
}

function isFindingIgnoredBySpecs(
  finding: ImageScanFinding,
  specs: Array<IgnoreSpec>,
): boolean {
  for (const spec of specs) {
    if (isFindingIgnoredBySpec(finding, spec)) {
      return true;
    }
  }
  return false;
}

const isFindingIgnored = async (
  finding: ImageScanFinding,
): Promise<boolean> => {
  const ignored = await ignoreSpecs(ignoreSpecARN);
  if (isFindingIgnoredBySpecs(finding, ignored)) {
    return true;
  }
  return false;
};

const snoozeList = async (parameterARN: string): Promise<SnoozeList[]> => {
  const getParameterResult = await ssmClient.send(
    new GetParameterCommand({
      Name: parameterARN,
      WithDecryption: true,
    }),
  );

  assert(
    getParameterResult?.Parameter?.Value,
    "Failed to fetch snooze list from Parameter Store",
  );
  return JSON.parse(getParameterResult.Parameter.Value) as Array<SnoozeList>;
};

const clusterSnoozed = async (
  cluster: string,
  snoozed: Array<SnoozeList>,
): Promise<boolean> => {
  const expiry = Date.now() - 604800000;
  for (const snooze of snoozed) {
    const snoozeDate = Date.parse(snooze.date);
    logger.debug(
      `Cluster: ${snooze.cluster} Date: ${snoozeDate} Expiry: ${expiry}`,
    );
    if (snooze.cluster === cluster && snoozeDate >= expiry) {
      return true;
    }
  }
  return false;
};

const isClusterSnoozed = async (cluster: string): Promise<boolean> => {
  return clusterSnoozed(cluster, await snoozeList(snoozedClustersARN));
};

export { isFindingIgnored, isClusterSnoozed };
