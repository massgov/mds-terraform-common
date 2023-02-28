import { z } from 'zod';
import { logLevels } from "../lib/log/LogLevel";

export const ConfigSchema = z.object({
  region: z.string().min(1),
  paramPrefix: z.string().min(1),
  sendToTeams: z.boolean(),
  minLogLevel: z.enum(logLevels),
  token: z.string().min(50),
})

type Config = z.infer<typeof ConfigSchema>
export default Config;
