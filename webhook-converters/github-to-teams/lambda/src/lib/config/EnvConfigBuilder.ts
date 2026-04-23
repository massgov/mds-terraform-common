import Config, { ConfigSchema } from "../../types/Config";
import { LogLevel } from "../log/LogLevel";
import Severity from "../../types/Severity";

export default class EnvConfigBuilder {

  protected getEnvVar(name: string): string | undefined {
    return process.env[name]
  }

  build(): Config {
    const minSeveritiesEnv = this.getEnvVar('MIN_SEVERITIES');
    const minSeverities: Severity[] | undefined = minSeveritiesEnv && minSeveritiesEnv.trim() !== ''
      ? minSeveritiesEnv.split(',').map(s => s.trim()).filter(s => s !== '').map(s => s as Severity)
      : undefined;

    const result: Partial<Config> = {
      region: this.getEnvVar('AWS_REGION'),
      paramPrefix: this.getEnvVar('CONFIGURABLE_PARAM_PREFIX'),
      sendToTeams: (this.getEnvVar('SEND_TO_TEAMS') === 'yes'),
      minLogLevel: this.getEnvVar('MIN_LOG_LEVEL') as LogLevel,
      token: this.getEnvVar('PATH_TOKEN'),
      minSeverities,
    }

    return ConfigSchema.parse(result)
  }

}
