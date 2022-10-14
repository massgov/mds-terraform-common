import {
  Api,
  ApiGatewayV2Client,
  GetApisCommand,
  GetApisCommandInput, GetApisCommandOutput
} from "@aws-sdk/client-apigatewayv2";
import Scanner from "../../types/Scanner";
import {ServiceType} from "../../types/Service";
import Interconnections from "../Interconnections";
import getPaginated from "../util/getPaginated";
import ScanLogger from "../ScanLogger";
import BaseScanner from "./BaseScanner";

export default class HttpApiGatewayScanner extends BaseScanner implements Scanner {

  protected client: ApiGatewayV2Client

  protected serviceType: ServiceType = "httpapi"

  constructor(client: ApiGatewayV2Client, logger: ScanLogger) {
    super(logger)

    this.client = client
  }

  protected async doScan(interconnections: Interconnections) {
    // @todo Add support for custom domain names once we have at least one for
    //   an HTTP API Gateway.

    this.logger.log('==== Scanning HTTP APIs... ====')

    for await (const api of this.getApis()) {
      if (!api.ApiId) {
        this.logger.error(`Found HTTP API without an ID!`)
        continue;
      }

      this.logger.debug(`- HTTP API: ${api.ApiId}:`)

      // Add default endpoint, if enabled.
      if (!api.DisableExecuteApiEndpoint) {
        const endpoint = api.ApiEndpoint
        if (!endpoint) {
          this.logger.error(`The ${api.ApiId} HTTP API doesn't have a default endpoint.`)
          continue;
        }

        interconnections.addPointToServiceLink(
          endpoint,
          this.serviceType,
          api.ApiId
        )
        this.logger.debug(`-- Default endpoint: ${endpoint}`)
      }
      else {
        this.logger.debug('-- Default endpoint is disabled.')
      }
    }

    this.logger.log('==== The HTTP API scan is complete. ====')
  }

  async* getApis(): AsyncGenerator<Api> {
    const limit = 50;
    const CommandClass = GetApisCommand;

    const input: GetApisCommandInput = {
      MaxResults: limit.toString(),
    }

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: GetApisCommandOutput) {
        const apis = data.Items
        if (!apis) {
          throw new Error('Unable to list HTTP APIs.')
        }

        for (const api of apis) {
          yield api
        }

        if (data.NextToken === undefined) {
          return true
        }

        input.NextToken = data.NextToken
      }
    })
  }

}
