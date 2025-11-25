import {
  AttachVolumeCommand,
  DescribeImagesCommand,
  DescribeInstancesCommand,
  DescribeVolumesCommand,
  DetachVolumeCommand,
  EC2Client,
  InstanceStateName,
  RunInstancesCommand,
  TerminateInstancesCommand,
  VolumeAttachmentState,
  waitUntilInstanceRunning,
  waitUntilVolumeAvailable,
  waitUntilVolumeInUse,
  type DescribeImagesResult,
  type Image,
  type Instance
} from "@aws-sdk/client-ec2";
import {
  GetCommandInvocationCommand,
  SendCommandCommand,
  SSMClient,
  waitUntilCommandExecuted,
} from "@aws-sdk/client-ssm";
import assert from "assert";
import type { EventBridgeEvent, Handler } from "aws-lambda";
import { config } from "dotenv";
import pino from "pino";
import zod from "zod";

config();
const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
});
const ec2 = new EC2Client();
const ssm = new SSMClient();

interface Env {
  PROTO_ID: string;
  VOLUME_ID: string;
  LAUNCH_TEMPLATE_ID: string;
  DEVICE_NAME:string;
  AMI_QUERY_JSON: string;
}

const getEnv = (env: Record<string, string | undefined>): Env => {
  assert(
    typeof env["PROTO_ID"] === "string",
    "Required variable PROTO_ID missing from env"
  );
  assert(
    typeof env["VOLUME_ID"] === "string",
    "Required variable VOLUME_ID missing from env"
  );
  assert(
    typeof env["LAUNCH_TEMPLATE_ID"] === "string",
    "Required variable LAUNCH_TEMPLATE_ID missing from env"
  );
  assert(
    typeof env["DEVICE_NAME"] === "string",
    "Required variable DEVICE_NAME missing from env"
  );
  assert(
    typeof env["AMI_QUERY_JSON"] === "string",
    "Required variable AMI_QUERY_JSON missing from env"
  );

  return {
    PROTO_ID: env["PROTO_ID"],
    VOLUME_ID: env["VOLUME_ID"],
    LAUNCH_TEMPLATE_ID: env["LAUNCH_TEMPLATE_ID"],
    DEVICE_NAME: env["DEVICE_NAME"],
    AMI_QUERY_JSON: env["AMI_QUERY_JSON"],
  };
};

const amiQuerySchema = zod.array(
  zod.object({
    name: zod.string(),
    values: zod.array(zod.string()),
  })
);
type AmiQuery = zod.output<typeof amiQuerySchema>;

const getLatestAmi = async (amiQuery: AmiQuery): Promise<Image | undefined> => {
  let next = undefined;
  const images = new Array<Image>();
  do {
    logger.trace({ amiQuery }, "Searching for AMIs matching query");
    const amiSearchResult: DescribeImagesResult = await ec2.send(
      new DescribeImagesCommand({
        Owners: ["self", "amazon"],
        Filters: amiQuery.map(({ name, values }) => ({
          Name: name,
          Values: values,
        })),
        MaxResults: 100,
        NextToken: next,
      })
    );
    images.push(...(amiSearchResult.Images ?? []));
    next = amiSearchResult.NextToken;
  } while (next);

  logger.debug({ amiQuery }, `Found ${images.length} AMI(s) matching query`);
  // Sort by created date descending
  return images.toSorted((a, b) => {
    if (!a.CreationDate && !b.CreationDate) {
      return 0;
    }
    if (!a.CreationDate) {
      return 1;
    }
    if (!b.CreationDate) {
      return -1;
    }
    return (
      new Date(b.CreationDate).valueOf() - new Date(a.CreationDate).valueOf()
    );
  })[0];
};

const unmountPartitionOnInstance = async (
  instanceId: string,
): Promise<{ success: boolean }> => {
  logger.debug(
    { instanceId },
    "Unmounting partition from instance"
  );
  const sendCommandResult = await ssm.send(
    new SendCommandCommand({
      InstanceIds: [instanceId],
      DocumentName: "AWS-RunShellScript",
      Comment: "Unmount user data partition",
      Parameters: {
        commands: [
          "set -e",
          `mountpoint=$(lsblk -o MOUNTPOINT,PATH --json | jq -r '.blockdevices[] | select(.mountpoint == "/home").path')`,
          'if [ -n "${mountpoint}" ]; then umount $mountpoint; else echo "Nothing to do - ${mountpoint} not mounted"; fi',
        ],
      },
    })
  );
  await waitUntilCommandExecuted(
    { client: ssm, maxWaitTime: 90 },
    {
      CommandId: sendCommandResult.Command?.CommandId,
      InstanceId: instanceId,
    }
  );
  logger.debug(
    { instanceId },
    "Unmount command has finished; checking invocation status"
  );
  const getCommandInvicationResult = await ssm.send(
    new GetCommandInvocationCommand({
      CommandId: sendCommandResult.Command?.CommandId,
      InstanceId: instanceId,
    })
  );
  return { success: getCommandInvicationResult.Status === "Success" };
};

const getInstance = async (protoId: string): Promise<Instance | undefined> => {
  logger.debug({ protoId }, "Looking up AMI currently being used by instance");
  const describeInstancesResult = await ec2.send(
    new DescribeInstancesCommand({
      Filters: [
        {
          Name: "instance-state-name",
          Values: [
            InstanceStateName.pending,
            InstanceStateName.running,
            InstanceStateName.stopped,
            InstanceStateName.stopping,
          ],
        },
        {
          Name: "tag:proto-id",
          Values: [protoId],
        },
      ],
    })
  );
  const allInstances =
    describeInstancesResult.Reservations?.flatMap(
      ({ Instances }) => Instances
    ).filter(<T>(val: T | undefined): val is T => Boolean(val)) ?? [];
  const instance = allInstances.length === 1 ? allInstances[0] : undefined;
  return instance;
};

const recreateInstance = async (
  instanceId: string | null,
  volumeId: string,
  deviceName: string,
  launchTemplateId: string,
  imageId: string,
): Promise<{ newInstanceId: string }> => {
  logger.debug({ instanceId, volumeId }, "Detaching volume from instance");
  const describeVolumeResult = await ec2.send(
    new DescribeVolumesCommand({
      VolumeIds: [volumeId],
    })
  );
  assert(
    describeVolumeResult.Volumes?.length === 1
      && describeVolumeResult.Volumes[0],
    "Got unexpected response when checking volume status"
  );
  if (
    instanceId &&
    describeVolumeResult.Volumes[0].Attachments?.some(
      ({ InstanceId }) => InstanceId === instanceId
    )
  ) {
    await ec2.send(
      new DetachVolumeCommand({
        InstanceId: instanceId,
        VolumeId: volumeId,
      })
    );
  }
  await waitUntilVolumeAvailable(
    { client: ec2, maxWaitTime: 90 },
    { VolumeIds: [volumeId] }
  );
  logger.debug({ instanceId, volumeId }, "Volume is now available");

  logger.debug(
    { launchTemplateId, imageId },
    "Launching new instance from template"
  );
  const runInstancesResult = await ec2.send(
    new RunInstancesCommand({
      ImageId: imageId,
      LaunchTemplate: {
        LaunchTemplateId: launchTemplateId,
        Version: "$Latest",
      },
      MinCount: 1,
      MaxCount: 1,
    })
  );
  const newInstanceId = (runInstancesResult.Instances ?? [])[0]?.InstanceId;
  assert(newInstanceId, "Couldn't launch new instance");
  await waitUntilInstanceRunning(
    {
      client: ec2,
      maxWaitTime: 120,
    },
    { InstanceIds: [newInstanceId] }
  );
  logger.debug({ newInstanceId }, "New instance is now running");

  logger.debug(
    { newInstanceId, volumeId, device: deviceName },
    "Attaching volume to new instance"
  );
  await ec2.send(
    new AttachVolumeCommand({
      VolumeId: volumeId,
      InstanceId: newInstanceId,
      Device: deviceName
    })
  );
  await waitUntilVolumeInUse(
    {
      client: ec2,
      maxWaitTime: 60,
    },
    {
      VolumeIds: [volumeId],
      Filters: [
        { Name: "attachment.instance-id", Values: [newInstanceId] },
        { Name: "attachment.status", Values: [VolumeAttachmentState.attached] },
      ],
    }
  );
  logger.debug(
    { newInstanceId, volumeId, device: deviceName },
    "Volume is now attached to new intance"
  );

  if (instanceId) {
    logger.debug({ instanceId }, "Terminating old instance");
    await ec2.send(
      new TerminateInstancesCommand({
        InstanceIds: [instanceId],
      })
    );
  }

  return {
    newInstanceId,
  };
};

type Event = EventBridgeEvent<"Scheduled Event", {}> & { force?: boolean };

export const handler: Handler<Event, void> = async (event, context) => {
  const force = event.force ?? false;
  logger.setBindings({
    forceRecreate: force ? 'true' : 'false',
    invokedFunctionArn: context.invokedFunctionArn,
    awsRequestId: context.awsRequestId,
  });

  const env = getEnv(process.env);

  const amiQuery = JSON.parse(env.AMI_QUERY_JSON);
  const parsedAmiQuery = await amiQuerySchema.safeParseAsync(amiQuery);
  assert(
    parsedAmiQuery.success,
    "Invalid AMI_QUERY_JSON; expected a list of { name, values } maps"
  );
  const latestAmi = await getLatestAmi(parsedAmiQuery.data);
  assert(
    latestAmi && latestAmi.ImageId,
    "Found no available AMIs matching AMI_QUERY_JSON"
  );

  const instance = await getInstance(env.PROTO_ID);
  assert(
    force || instance,
    `Could not find existing instance with proto-id ${env.PROTO_ID}`
  );
  if (instance) {
    assert(
      instance.InstanceId,
      "Instance doesn't have an ID - is that even possible?"
    )
    if (!force && latestAmi.ImageId && latestAmi.ImageId === instance.ImageId) {
      logger.info(
        { imageId: latestAmi.ImageId },
        "Target instance already using latest AMI"
      );
      return;
    }
    const unmountResult = await unmountPartitionOnInstance(
      instance.InstanceId,
    );
    assert(unmountResult.success, "Can't safely detach volume from instance");
  }
  const { newInstanceId } = await recreateInstance(
    instance?.InstanceId ?? null,
    env.VOLUME_ID,
    env.DEVICE_NAME,
    env.LAUNCH_TEMPLATE_ID,
    latestAmi.ImageId
  );
  logger.info(
    { newInstanceId, imageId: latestAmi.ImageId, volumeId: env.VOLUME_ID },
    "Instance has been successfully recreated"
  );
};
