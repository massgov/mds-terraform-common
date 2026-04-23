import { z } from 'zod';
import { logLevels } from "../lib/log/LogLevel";
import Severity from './Severity';

const severities: [Severity, ...Severity[]] = ['low', 'medium', 'high', 'critical'];

export const ConfigSchema = z.object({
  region: z.string().min(1),
  paramPrefix: z.string().min(1),
  sendToTeams: z.boolean(),
  minLogLevel: z.enum(logLevels),
  token: z.string().min(50),
  minSeverities: z.array(z.enum(severities)).optional(),
})

type Config = z.infer<typeof ConfigSchema>
export default Config;
