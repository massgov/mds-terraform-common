import { SNSEventRecord } from "aws-lambda";

export type MessageCardSection = Partial<{
  startGroup: boolean;
  activityTitle: string;
  activitySubtitle: string;
  activityImage: string;
  facts: Array<{
    name: string;
    value: string;
  }>;
  text: string;
}>;

// this is actually a union type, but for our purposes
// we're limiting it to just URI actions
export interface MessageCardAction {
  "@type": "OpenUri";
  name: string;
  targets: Array<{
    os: "default" | "windows" | "iOS" | "android";
    uri: string;
  }>;
}

export interface MessageCard {
  "@type": "MessageCard";
  "@context": "https://schema.org/extensions";
  summary: string;
  themeColor?: string;
  title: string;
  sections: Array<MessageCardSection>;
  potentialAction: Array<MessageCardAction>;
}

export type TopicMap = Array<{
  topic_arn: string;
  human_name: string;
  emoji_uni_hex: string;
}>;

export interface WithMessageCard {
  record: SNSEventRecord;
  messageCard: MessageCard;
  hasMappedTopic: boolean;
}

export type WithPublishResult = WithMessageCard & {
  publishResult: {
    success: boolean;
    error: string | null;
  };
};
