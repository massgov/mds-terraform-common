import TeamsWebhookPayload from "../types/TeamsWebhookPayload";
import { IncomingWebhook, IncomingWebhookResult } from "ms-teams-webhook";

export default async function sendToTeams(
  url: string,
  payload: TeamsWebhookPayload
): Promise<IncomingWebhookResult | undefined> {
  const webhook = new IncomingWebhook(url);
  return webhook.send(payload)
}
