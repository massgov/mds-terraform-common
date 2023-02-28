import {
  GetParametersCommand,
  SSMClient
} from "@aws-sdk/client-ssm";
import ConfigurableParams, { ParamsSchema } from "../../types/ConfigurableParams";
import Config from "../../types/Config";

export default class ConfigurableParamsReader {

  protected region: string

  protected paramPrefix: string

  protected promise: Promise<ConfigurableParams>|undefined

  constructor({
    region,
    paramPrefix
  }: Config) {
    if (paramPrefix.length < 10) {
      throw new Error(`The SSM parameter prefix '${paramPrefix}' is too short.`)
    }

    this.region = region
    this.paramPrefix = paramPrefix
  }

  async getConfig(): Promise<ConfigurableParams> {
    if (this.promise === undefined) {
      this.promise = this.loadParams();
    }

    return this.promise
  }

  protected async loadParams(): Promise<ConfigurableParams> {
    const normalizedPrefix = this.paramPrefix.replace(/\/+$/, '')
    const teamsWebhookParamName = `${normalizedPrefix}/teams-webhook`
    const paramNameToKeyMap: Record<string, keyof ConfigurableParams> = {
      [`${normalizedPrefix}/github-secret`]: 'githubSecret',
      [teamsWebhookParamName]: 'teamsWebhookUrl'
    };

    const client = new SSMClient({region: this.region});
    const command = new GetParametersCommand({
      Names: Object.keys(paramNameToKeyMap),
      WithDecryption: true
    })
    const response = await client.send(command)

    const result: Partial<ConfigurableParams> = {};
    if (response.Parameters?.length) {
      for (const param of response.Parameters) {
        const paramName = param.Name
        if (paramName === undefined) {
          throw new Error(`The parameter name is missing.`)
        }

        const paramValue = param.Value
        if (paramValue === undefined) {
          throw new Error(`The ${paramName} parameter value is missing.`)
        }

        const keyName = paramNameToKeyMap[paramName];
        if (keyName === undefined) {
          throw new Error(`Unexpected ${paramName} parameter was returned.`)
        }

        result[keyName] = paramValue
      }
    }

    return ParamsSchema.parse(result)
  }

}
