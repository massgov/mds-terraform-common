import Config from "../types/Config";
import {LogLevel} from "./ScanLogger";

export default class EnvConfigBuilder {

  protected getEnvVar(name: string): string {
    if (process.env[name] === undefined) {
      throw new Error(`The mandatory environment variable is missing: ${name}`)
    }

    return process.env[name]
  }

  protected getOptionalEnvVar(name: string): string|undefined {
    return process.env[name]
  }

  build(): Config {
    return {
      region: this.getEnvVar('AWS_REGION'),
      allowedPointsParamName: this.getOptionalEnvVar('ALLOWED_POINTS_PARAMETER'),
      minLogLevel: this.getEnvVar('MIN_LOG_LEVEL') as LogLevel,
      reportSnsTopic: this.getEnvVar('REPORT_SNS_TOPIC')
    }
  }

}
