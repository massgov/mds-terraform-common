import { handler } from "./index";
import { randomInt } from "crypto";

const noop = () => {};

/**
 * Example usage:
    TOPIC_MAP='[{ "human_name": "Test Topic", "topic_arn": "arn:partition:service:region:account-id:12345", "icon_url": "https://mayflower.digital.mass.gov/core/static/media/stateseal-black.5188ad6f.png" }]' \
    TEAMS_WEBHOOK_URL='https://abc123foobaz.m.pipedream.net' \
    npx ts-node cli.ts;
 */
const run = async (): Promise<void> => {
  await handler(
    {
      Records: [
        {
          EventVersion: "1",
          EventSubscriptionArn: "arn:partition:service:region:account-id:00000",
          EventSource: "",
          Sns: {
            SignatureVersion: "1",
            Timestamp: new Date().toISOString(),
            Signature: `${randomInt(10000)}`,
            SigningCertUrl: "",
            MessageId: `${randomInt(10000)}`,
            Message: JSON.stringify({
              a: "A",
              b: 1234,
              c: "C",
            }),
            MessageAttributes: {},
            Type: "Notification",
            UnsubscribeUrl: "",
            TopicArn: "arn:partition:service:region:account-id:12345",
            Subject: "Test Subject",
          },
        },
      ],
    },
    {
      callbackWaitsForEmptyEventLoop: false,
      functionName: "test-function",
      functionVersion: `${randomInt(10000)}`,
      invokedFunctionArn: "arn:partition:service:region:account-id:55555",
      memoryLimitInMB: "1",
      awsRequestId: `${randomInt(10000)}`,
      logGroupName: "log-group-1",
      logStreamName: "log-stream-1",
      getRemainingTimeInMillis: () => 1,
      done: noop,
      fail: noop,
      succeed: noop,
    },
    noop
  );
};

run();
