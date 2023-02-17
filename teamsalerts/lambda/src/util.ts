import { SNSEvent } from "aws-lambda";
import { MessageCard, TopicMap } from "./types";

type TopicInfo = Pick<TopicMap[number], 'emoji_uni_hex' | 'human_name'>;

const MAYFLOWER_DUCKLING_YELLOW = 'F6C51B';
const DEFAULT_TOPIC_INFO : TopicInfo = {
  emoji_uni_hex: '26AO', // ⚠️
  human_name: 'Unnamed Topic',
}

const getImageData = (emojiHex: string) => {
  const base64 = Buffer.from(`
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" height="100">
      <title>emoji</title>
      <text y="85" style="width: 100%; height:100%; font-size: 100px">&#x${emojiHex};</text> 
    </svg>
  `).toString('base64url');
  return `data:text/svg;base64,${base64}`;
}

export const transformSnsEventToMessageCards = (event: SNSEvent, topicMap: TopicMap): Array<MessageCard | null> => {
  return event.Records.map((r) => {
    const {
      Message,
      MessageAttributes,
      Subject,
      Timestamp,
      TopicArn
    } = r.Sns;

    const { emoji_uni_hex, human_name } = topicMap.find(
      ({ topic_arn }) => topic_arn.toUpperCase() === TopicArn.toUpperCase()
    ) ?? DEFAULT_TOPIC_INFO;

    const message: MessageCard = {
      "@context":"https://schema.org/extensions",
      "@type":"MessageCard",
      summary: `SNS Alert: ${TopicArn}`,
      themeColor: MAYFLOWER_DUCKLING_YELLOW,
      title: `SNS Alert from ${human_name}`,
      sections: [
        {
          activityTitle: Subject,
          activitySubtitle: `@ ${Timestamp}`,
          activityImage: getImageData(emoji_uni_hex),
          text: Message,
          facts: Object.entries(MessageAttributes).map(([name, { Type, Value }]) => ({
            name,
            value: `${Type} — ${Value}`
          }))
        }
      ],
      potentialAction: []
    };

    return message;
  });
}
