import assert from "assert";
import { SNSHandler } from "aws-lambda";
import { TopicMap } from "./types";
import { consume, pipeline, tap } from "streaming-iterables";
import { enrichWithMessageCards, publishToTeams, getWebhookUrl } from "./util";

const handler: SNSHandler = async function (event, context) {
  const webhookUrl = await getWebhookUrl();
  assert(process.env.TOPIC_MAP && typeof process.env.TOPIC_MAP === "string");

  const topicMap = <TopicMap>JSON.parse(process.env.TOPIC_MAP);

  await pipeline(
    () => event.Records,
    (records) => enrichWithMessageCards(records, topicMap, context),
    tap((record) =>
      record.hasMappedTopic
        ? undefined
        : console.warn(`Unmapped topic: ${record.record.Sns.TopicArn}`)
    ),
    (records) => publishToTeams(records, webhookUrl),
    tap((record) =>
      record.publishResult.success
        ? console.log(
            `Successfully published ${record.record.Sns.MessageId} from ${record.record.Sns.TopicArn} to Teams`
          )
        : console.error(
            `Failed to publish ${record.record.Sns.MessageId} from ${record.record.Sns.TopicArn} to Teams: %s`,
            record.publishResult.error
          )
    ),
    consume
  );
};

export { handler };
