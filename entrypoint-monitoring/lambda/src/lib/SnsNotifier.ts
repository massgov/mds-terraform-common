import Config from "../types/Config";
import {PublishCommand, SNSClient} from "@aws-sdk/client-sns";

export default class SnsNotifier {

  protected config: Config

  protected client: SNSClient

  constructor(client: SNSClient, config: Config) {
    this.client = client
    this.config = config
  }

  async send(message: string) {
    const command = new PublishCommand({
      Message: message,
      TopicArn: this.config.reportSnsTopic,
    })
    return this.client.send(command)
  }

}
