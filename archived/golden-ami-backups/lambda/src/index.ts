import pino from "pino";
import { EventBridgeHandler } from "aws-lambda";
import { GetParameterCommand, SSMClient } from "@aws-sdk/client-ssm";
import { PublishCommand, SNSClient } from "@aws-sdk/client-sns";
import assert from "assert";
import {
  CopyImageCommand,
  EC2Client,
  waitUntilImageAvailable,
} from "@aws-sdk/client-ec2";
import dayjs from "dayjs";
import { randomUUID } from "crypto";

type Handler = EventBridgeHandler<
  "Parameter Store Change",
  {
    operation: "Create" | "Update" | "Delete";
    name: string;
    type: "String" | "StringList" | "SecureString";
    description: string;
  },
  void
>;

type Env = {
  SOURCE_IMAGE_PARAMETER_ARN: string;
  DEST_IMAGE_PREFIX: string;
  REENCRYPTION_KEY_ID: string;
  ERROR_TOPIC_ARN: string;
};

const defaultLogger = pino({ level: process.env.LOG_LEVEL ?? "debug" });
const ssmClient = new SSMClient();
const snsClient = new SNSClient();
const ec2Client = new EC2Client();

const MAX_COPY_WAIT_TIME_MINUTES = 10;

const getEnv = (): Env => {
  const {
    SOURCE_IMAGE_PARAMETER_ARN,
    ERROR_TOPIC_ARN,
    REENCRYPTION_KEY_ID,
    DEST_IMAGE_PREFIX,
  } = process.env;

  assert(
    typeof SOURCE_IMAGE_PARAMETER_ARN === "string",
    "'SOURCE_IMAGE_PARAMETER_ARN' missing from environment",
  );
  assert(
    typeof ERROR_TOPIC_ARN === "string",
    "'ERROR_TOPIC_ARN' missing from environment",
  );
  assert(
    typeof REENCRYPTION_KEY_ID === "string",
    "'REENCRYPTION_KEY_ID' missing from environment",
  );

  return {
    SOURCE_IMAGE_PARAMETER_ARN,
    ERROR_TOPIC_ARN,
    REENCRYPTION_KEY_ID,
    DEST_IMAGE_PREFIX: DEST_IMAGE_PREFIX ?? "ssr-golden-aws-linux2",
  };
};

const arrayOf = <T>(val: T | Array<T>): Array<T> => {
  return Array.isArray(val) ? val : [val];
};

const handler: Handler = async (event, context, callback): Promise<void> => {
  const {
    SOURCE_IMAGE_PARAMETER_ARN,
    ERROR_TOPIC_ARN,
    DEST_IMAGE_PREFIX,
    REENCRYPTION_KEY_ID,
  } = getEnv();
  const logger = defaultLogger.child({
    eventId: event.id,
    functionArn: context.invokedFunctionArn,
    awsRequestId: context.awsRequestId,
  });

  const handleError = async (
    messageOrMessageParts: string | Array<string>,
  ): Promise<void> => {
    logger.error(arrayOf(messageOrMessageParts).join(","));

    const messageParts = ["### Golden AMI backup automation has failed"];
    messageParts.push(...arrayOf(messageOrMessageParts));
    const message = messageParts.join("\n\n");
    await snsClient.send(
      new PublishCommand({
        TopicArn: ERROR_TOPIC_ARN,
        Message: message,
      }),
    );
    return callback(message);
  };

  logger.debug(
    `Received EventBridge event from '${event.source}': '${event["detail-type"]}'`,
  );

  if (event.detail.operation === "Delete") {
    logger.warn(
      `Received a trigger from an unexpected parameter change type: '${event.detail.operation}'`,
    );
    return;
  }

  logger.debug(
    `Reading '${event.detail.type}:${event.detail.name}' from Parameter Store`,
  );

  const getParameterResult = await ssmClient.send(
    new GetParameterCommand({
      Name: event.detail.name,
      WithDecryption: event.detail.type === "SecureString",
    }),
  );

  let goldenAmiId: string | undefined;
  const goldenAmiParam = getParameterResult.Parameter;
  if (!goldenAmiParam) {
    const msg = `Received trigger from invalid SSM parameter: '${event.detail.name}'`;
    return handleError(msg);
  }
  if (goldenAmiParam.ARN !== SOURCE_IMAGE_PARAMETER_ARN) {
    const msg = `Received trigger from unexpected parameter change: '${event.detail.name}'`;
    return handleError(msg);
  }
  goldenAmiId = goldenAmiParam.Value;
  if (!goldenAmiId) {
    const msg = `SSM parameter '${goldenAmiParam.ARN}' is missing value`;
    return handleError(msg);
  }

  const dateStamp = dayjs().format("YYYY-MM-DD");
  const nonce = randomUUID().slice(0, 8);
  const backupImageName = `${DEST_IMAGE_PREFIX}-${dateStamp}-${nonce}`;
  logger.debug(`Backing up Golden AMI to '${backupImageName}'`);

  const copyImageResult = await ec2Client.send(
    new CopyImageCommand({
      Name: backupImageName,
      Description: `DS SSR Golden AMI (source image: ${goldenAmiId})`,
      SourceImageId: goldenAmiId,
      SourceRegion: "us-east-1",
      KmsKeyId: REENCRYPTION_KEY_ID,
      Encrypted: true,
    }),
  );
  if (!copyImageResult.ImageId) {
    const msg =
      "CopyImage command failed to return new image ID when copying source image";
    return handleError(msg);
  }
  logger.info(
    `Initiated creation of backup image '${copyImageResult.ImageId}'`,
  );

  try {
    logger.debug(
      `Waiting ${MAX_COPY_WAIT_TIME_MINUTES} minutes for ${copyImageResult.ImageId} to become available`,
    );
    const result = await waitUntilImageAvailable(
      {
        client: ec2Client,
        maxDelay: 30,
        maxWaitTime: 60 * MAX_COPY_WAIT_TIME_MINUTES,
      },
      {
        ImageIds: [copyImageResult.ImageId],
      },
    );
    assert(
      result.state === "SUCCESS",
      `Backup image failed to become available after ${MAX_COPY_WAIT_TIME_MINUTES} minutes: ${result.reason}`,
    );
  } catch (err) {
    const msg =
      err instanceof Error ? [`Error: ${err.name}`, err.message] : `${err}`;
    return handleError(msg);
  }

  logger.info(
    `Image backup '${copyImageResult.ImageId}' has been successfully created`,
  );
  return;
};

export { handler };
