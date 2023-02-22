import { Context, SNSEventRecord } from "aws-lambda";
import { AnyIterable, batch } from "streaming-iterables";
import {
  MessageCard,
  MessageCardSection,
  TopicMap,
  WithMessageCard,
  WithPublishResult,
} from "./types";
import { IncomingWebhook } from "ms-teams-webhook";

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

    if (Object.keys(MessageAttributes).length > 0) {
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
): AsyncIterable<WithPublishResult> {
  const webhook = new IncomingWebhook(webhookUrl);
  for await (const chunk of batch(10, records)) {
    const promises = chunk.map(async (record) => {
      let publishResult;
      try {
        await webhook.send(record.messageCard);
        publishResult = {
          success: true,
          error: null
        }
      } catch(e) {
        const error = e instanceof Error
          ? e.message
          : `${e}`;
        publishResult = {
          success: false,
          error,
        }
      }

      return {
        ...record,
        publishResult
      };
    });


    const results = await Promise.all(promises);
    yield* results;
  }
};
