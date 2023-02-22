import { Context, SNSEventRecord } from "aws-lambda";
import { request } from "http";
import { AnyIterable, batch } from "streaming-iterables";
import { parse } from "url";
import {
  MessageCard,
  MessageCardSection,
  TopicMap,
  WithMessageCard,
  WithPublishResult,
} from "./types";

type TopicInfo = Pick<TopicMap[number], "icon_url" | "human_name">;

const MAYFLOWER_DUCKLING_YELLOW = "F6C51B";
const DEFAULT_TOPIC_INFO: TopicInfo = {
  icon_url: "https://img.icons8.com/color/100/general-warning-sign.png", // ⚠️
  human_name: "Unnamed Topic",
};

const formatMessagePart = (value: unknown): string => {
  if (typeof value === "object") {
    return "`" + JSON.stringify(value) + "`";
  }
  return `${value}`;
};

export const enrichWithMessageCards = async function* (
  records: AnyIterable<SNSEventRecord>,
  topicMap: TopicMap,
  context: Context
) {
  for await (const record of records) {
    const { Message, MessageAttributes, Subject, Timestamp, TopicArn } =
      record.Sns;

    const mappedTopic = topicMap.find(
      ({ topic_arn }) =>
        topic_arn.toUpperCase().trim() === TopicArn.toUpperCase().trim()
    );

    const { human_name, icon_url } = mappedTopic ?? DEFAULT_TOPIC_INFO;

    const sections = new Array<MessageCardSection>();
    let messageJson: Object | null = null;
    try {
      messageJson = JSON.parse(Message);
    } catch (_) {
      // no op
    }

    const activityTitle = Subject || `New message on **${TopicArn}**`;
    const activitySubtitle = new Date(Timestamp).toUTCString();
    const activityImage = icon_url;

    sections.push({
      activityTitle,
      activitySubtitle,
      activityImage,
      ...(messageJson
        ? {
            text: "#### Message contents:",
            facts: Object.entries(messageJson).map(([key, value]) => ({
              name: key,
              value: formatMessagePart(value),
            })),
          }
        : {
            text: Message,
            facts: [],
          }),
    });

    if (MessageAttributes) {
      sections.push({
        startGroup: true,
        text: "#### Message attributes:",
        facts: Object.entries(MessageAttributes).map(
          ([name, { Type, Value }]) => ({
            name,
            value: `${Type} - ${Value}`,
          })
        ),
      });
    }

    const messageCard: MessageCard = {
      "@context": "https://schema.org/extensions",
      "@type": "MessageCard",
      summary: `SNS alert: ${TopicArn}`,
      themeColor: MAYFLOWER_DUCKLING_YELLOW,
      title: `SNS alert from ${human_name}`,
      sections,
      potentialAction: [
        {
          "@type": "OpenUri",
          name: `View Logs`,
          targets: [
            {
              os: "default",
              uri: `https://console.aws.amazon.com/cloudwatch/home#logEventViewer:group=${
                context.logGroupName
              };stream=${context.logStreamName};start=${new Date()}`,
            },
          ],
        },
        {
          "@type": "OpenUri",
          name: `View Monitoring`,
          targets: [
            {
              os: "default",
              uri: `https://console.aws.amazon.com/lambda/home#/functions/${context.functionName}/versions/${context.functionVersion}?tab=monitoring`,
            },
          ],
        },
      ],
    };

    yield {
      record,
      hasMappedTopic: Boolean(mappedTopic),
      messageCard,
    };
  }
};

export const publishToTeams = async function* (
  records: AnyIterable<WithMessageCard>,
  webhookUrl: string
) {
  const urlParts = parse(webhookUrl);
  for await (const chunk of batch(10, records)) {
    const promises = chunk.map((record) => {
      const postData = JSON.stringify(record.messageCard);

      const options = {
        hostname: urlParts.hostname,
        port: 80,
        path: urlParts.path,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(postData),
        },
      };

      return new Promise<WithPublishResult>((resolve) => {
        const req = request(options, ({ statusCode, statusMessage }) => {
          const error =
            statusCode && statusCode < 300 && statusCode >= 200
              ? null
              : `Webhook URL returned ${statusCode} - ${statusMessage}`;
          resolve({
            ...record,
            publishResult: {
              success: !error,
              error,
            },
          });
        });

        req.on("error", (e) =>
          resolve({
            ...record,
            publishResult: {
              success: false,
              error: e.message,
            },
          })
        );

        req.write(postData);
        req.end();
      });
    });

    const results = await Promise.all(promises);
    yield* results;
  }
};
