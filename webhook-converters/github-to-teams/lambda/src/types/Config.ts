import { z } from 'zod';

export const ConfigSchema = z.object({
  region: z.string().min(1),
  paramPrefix: z.string().min(1),
  sendToTeams: z.boolean(),
})

type Config = z.infer<typeof ConfigSchema>
export default Config;
