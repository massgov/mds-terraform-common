import { Context, SNSEventRecord } from "aws-lambda";
import { AnyIterable, batch } from "streaming-iterables";
import {
  MessageCard,
  MessageCardSection,
  PublishResult,
  TopicMap,
  WithMessageCard,
  WithPublishResult,
} from "./types";
import { IncomingWebhook } from "ms-teams-webhook";
import assert from "assert";

type TopicInfo = Pick<TopicMap[number], "icon_url" | "human_name">;

// This strange order of control characters looks weird but experimenting in
// Microsoft's message card playground (https://messagecardplayground.azurewebsites.net/)
// has proven that this is what produces a newline
const MESSAGE_CARD_NEWLINE = "\n\r";
const MAYFLOWER_DUCKLING_YELLOW = "F6C51B";
const DEFAULT_TOPIC_INFO: TopicInfo = {
  icon_url: "https://img.icons8.com/color/100/general-warning-sign.png", // ⚠️
  human_name: "Unnamed Topic",
};

const formatMessagePart = (value: unknown): string => {
  if (typeof value === "object") {
    return (
      "`" +
      JSON.stringify(value, undefined, 1).replace(
        /\n ?/g,
        `\`${MESSAGE_CARD_NEWLINE}\``
      ) +
      "`"
    );
  }
  return wrapText(`${value}`);
};

const wrapText = (value: string, maxLineLength = 100): string => {
  return value.split(" ").reduce((acc, word): string => {
    const lastLineBreakIndex = acc.lastIndexOf(MESSAGE_CARD_NEWLINE);
    const lastLine =
      lastLineBreakIndex === -1 ? acc : acc.slice(lastLineBreakIndex);
    if (acc.length === 0) {
      return word;
    }
    if (lastLine.length + word.length < maxLineLength) {
      return `${acc} ${word}`;
    }
    return `${acc}${MESSAGE_CARD_NEWLINE}${word}`;
  }, "");
};

const getLogStreamConsoleURI = (context: Context): string => {
  assert(typeof process.env.AWS_REGION === "string");

  // for some reason, log group and log stream names need to be double-encoded
  // and then have the percent signs replaced with dollar signs
  const logGroupPart = encodeURIComponent(
    encodeURIComponent(context.logGroupName)
  ).replace("%", "$");
  const logStreamPart = encodeURIComponent(
    encodeURIComponent(context.logStreamName)
  ).replace("%", "$");
  return `https://${process.env.AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${process.env.AWS_REGION}#logsV2:log-groups/log-group/${logGroupPart}/log-events/${logStreamPart}`;
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
            text: "##### Message contents:",
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
        text: "##### Message attributes:",
        facts: Object.entries(MessageAttributes).map(
          ([name, { Type, Value }]) => ({
            name,
            value: wrapText(`${Type} - ${Value}`),
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
              uri: getLogStreamConsoleURI(context),
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
      let publishResult: PublishResult;
      try {
        await webhook.send(record.messageCard);
        publishResult = {
          success: true,
          error: null,
        };
      } catch (e) {
        const error = e instanceof Error ? e.message : `${e}`;
        publishResult = {
          success: false,
          error,
        };
      }

      return {
        ...record,
        publishResult,
      };
    });

    const results = await Promise.all(promises);
    yield* results;
  }
};
