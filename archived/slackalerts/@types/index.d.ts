declare module '@lastcall/sns-slack-alerts-consumer' {
  type TopicMap = Record<string, {
    username: string
    icon_emoji: string,
    as_user: boolean,
    channel: string,
  }>;

  export class SNSSlackPublisher {
    constructor(token: string, defaultMsg: { as_user: boolean, channel: string }, topicMap: TopicMap);
    async publish(record: import("@types/aws-lambda").SNSEventRecord): Promise<unknown>;
  }
}