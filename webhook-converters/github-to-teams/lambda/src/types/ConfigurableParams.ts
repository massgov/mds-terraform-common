import { z } from 'zod'

export const ParamsSchema = z.object({
  githubSecret: z.string(),
  teamsWebhookUrl: z.string(),
})

type ConfigurableParams = z.infer<typeof ParamsSchema>
export default ConfigurableParams;
