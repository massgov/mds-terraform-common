import Config, { ConfigSchema } from "../../types/Config";

export default class EnvConfigBuilder {

  protected getEnvVar(name: string): string|undefined {
    return process.env[name]
  }

  build(): Config {
    const result: Partial<Config> = {
      region: this.getEnvVar('AWS_REGION'),
      paramPrefix: this.getEnvVar('CONFIGURABLE_PARAM_PREFIX'),
      sendToTeams: (this.getEnvVar('SEND_TO_TEAMS') === 'yes')
    }

    return ConfigSchema.parse(result)
  }

}
