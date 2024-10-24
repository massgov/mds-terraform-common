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
  icon_url: string;
}>;

export interface WithMessageCard {
  record: SNSEventRecord;
  messageCard: MessageCard;
  hasMappedTopic: boolean;
}

export type PublishResult =
  | {
      success: true;
      error: null;
    }
  | {
      success: false;
      error: string;
    };

export type WithPublishResult = WithMessageCard & {
  publishResult: PublishResult;
};
