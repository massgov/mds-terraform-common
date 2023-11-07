import { SNSHandler } from "aws-lambda";
import { SNSSlackPublisher } from '@lastcall/sns-slack-alerts-consumer';
import assert from "assert";

const {
  SLACK_TOKEN,
  DEFAULT_CHANNEL,
  TOPIC_MAP
} = process.env;

assert(SLACK_TOKEN, 'SLACK_TOKEN was not provided');
assert(TOPIC_MAP);
assert(DEFAULT_CHANNEL);

// Slack message settings for topics that don't have a special setting:
const defaultMessage = {
  as_user: true,
  channel: DEFAULT_CHANNEL
}

type TopicMap = Record<string, {
  username: string
  icon_emoji: string,
  as_user: boolean,
  channel: string,
}>;

// Map of special topics to slack message bodies:
// Map of special topics to slack message bodies:
let topicMap: TopicMap = {};
JSON.parse(TOPIC_MAP).forEach((item: Record<string, unknown>) => {
  assert(typeof item.topic_arn === 'string');
  assert(typeof item.username === 'string');
  assert(typeof item.icon_emoji === 'string');
  assert(typeof item.channel === 'string');

  topicMap[item.topic_arn] = {
    username: item.username,
    icon_emoji: item.icon_emoji,
    as_user: false,
    channel: item.channel
  };
});

console.log(topicMap);

const publisher = new SNSSlackPublisher(SLACK_TOKEN, defaultMessage, topicMap);

const handler: SNSHandler = async function(data) {
  const records = data.Records.map((event) => {
    // Special handling for formatting ClamAV alert subject and message.
    if (event.Sns.TopicArn.includes('massgov-clamav-scan-status')) {
      const message = JSON.parse(event.Sns.Message);
      let output = ' ';
      for (const [key, value] of Object.entries(message)) {
        output += "*" + key + "*: " + value + "\n";
      }
      return {
        ...event,
        Sns: {
          ...event.Sns,
          Subject: 'ClamAV detected an infected file',
          Message: output
        }
      }
    }
    return event;
  });

  const messages = records.map(record => {
    return publisher.publish(record);
  });
  await Promise.all(messages);
};

export { handler };