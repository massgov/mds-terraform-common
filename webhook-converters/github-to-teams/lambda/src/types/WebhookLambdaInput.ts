import { z } from 'zod';
import { emitterEventNames } from "@octokit/webhooks";

export const WebhookLambdaInputSchema = z.object({
  id: z.string().min(1),
  name: z.enum(emitterEventNames),
  payload: z.string().min(1),
  signature: z.string().min(1),
});

type WebhookLambdaInput = z.infer<typeof WebhookLambdaInputSchema>

export default WebhookLambdaInput;
