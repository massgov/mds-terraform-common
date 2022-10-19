import {ServiceType} from "../../types/Service";
import {
  APIGatewayClient,
  BasePathMapping,
  DomainName,
  GetBasePathMappingsCommand,
  GetBasePathMappingsCommandInput,
  GetBasePathMappingsCommandOutput,
  GetDomainNamesCommand,
  GetDomainNamesCommandInput,
  GetDomainNamesCommandOutput,
  GetRestApisCommand, GetRestApisCommandInput, GetRestApisCommandOutput,
  RestApi
} from "@aws-sdk/client-api-gateway";
import Interconnections from "../Interconnections";
import getPaginated from "../util/getPaginated";
import Scanner from "../../types/Scanner";
import ScanLogger from "../ScanLogger";
import BaseScanner from "./BaseScanner";

export default class RestApiGatewayScanner extends BaseScanner implements Scanner {

  serviceType: ServiceType = "restapi"

  client: APIGatewayClient

  constructor(client: APIGatewayClient, logger: ScanLogger) {
    super(logger)

    this.client = client
  }

  protected async doScan(interconnections: Interconnections) {
    this.logger.log('==== Scanning custom domain names of REST APIs... ====')

    for await (const domainName of this.getCustomDomainNames()) {
      if (!domainName.domainName) {
        this.logger.error('Found a custom domain name for REST APIs without the actual domain name specified.')
        continue;
      }

      this.logger.debug(`- Custom domain name: ${domainName.domainName}`)

      for await (const basePathMapping of this.getBasePathMappings(domainName.domainName)) {
        if (!basePathMapping.restApiId) {
          this.logger.error(`Found a mapping of the ${domainName.domainName} custom domain name that has no REST API specified.`)
          continue;
        }

        if (domainName.distributionDomainName) {
          interconnections.addPointToServiceLink(
            domainName.distributionDomainName,
            this.serviceType,
            basePathMapping.restApiId
          )
          this.logger.debug(`-- Distribution domain name: ${domainName.distributionDomainName}`)
        }
        else if (domainName.regionalDomainName) {
          interconnections.addPointToServiceLink(
            domainName.regionalDomainName,
            this.serviceType,
            basePathMapping.restApiId
          )
          this.logger.debug(`-- Regional domain name: ${domainName.regionalDomainName}`)
        }
        else {
          this.logger.error(`Neither distribution nor redional entrypoint is defined on the ${domainName.domainName} custom domain.`)
          continue;
        }
      }
    }
    this.logger.log('==== The custom domain name scan of REST APIs is complete. ====')

    this.logger.log('==== Scanning REST APIs... ====')
    const region = await this.client.config.region()
    for await (const api of this.getApis()) {
      if (!api.id) {
        this.logger.error(`Found REST API without an ID!`)
        continue;
      }

      this.logger.debug(`- REST API: ${api.id}:`)

      // Add default endpoint, if enabled.
      if (!api.disableExecuteApiEndpoint) {
        const endpoint = `${api.id}.execute-api.${region}.amazonaws.com`
        interconnections.addPointToServiceLink(
          endpoint,
          this.serviceType,
          api.id
        )
        this.logger.debug(`-- Default endpoint: ${endpoint}`)
      }
      else {
        this.logger.debug('-- Default endpoint is disabled.')
      }
    }
    this.logger.log('==== The REST APIs scan is complete. ====')
  }

  async* getCustomDomainNames(): AsyncGenerator<DomainName> {
    const limit = 50;
    const CommandClass = GetDomainNamesCommand;

    const input: GetDomainNamesCommandInput = {
      limit,
    }

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: GetDomainNamesCommandOutput) {
        const domainNames = data.items || []
        for (const domainName of domainNames) {
          yield domainName
        }

        if (data.position === undefined) {
          return true;
        }

        input.position = data.position
      }
    })
  }

  async* getBasePathMappings(domainName: string): AsyncGenerator<BasePathMapping> {
    const limit = 50;
    const CommandClass = GetBasePathMappingsCommand;

    const input: GetBasePathMappingsCommandInput = {
      domainName,
      limit,
    }

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: GetBasePathMappingsCommandOutput) {
        const mappings = data.items || []
        for (const mapping of mappings) {
          yield mapping
        }

        if (data.position === undefined) {
          return true
        }

        input.position = data.position
      }
    })
  }

  async* getApis(): AsyncGenerator<RestApi> {
    const limit = 50;
    const CommandClass = GetRestApisCommand;

    const input: GetRestApisCommandInput = {
      limit,
    }

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: GetRestApisCommandOutput) {
        const apis = data.items || []
        for (const api of apis) {
          yield api
        }

        if (data.position === undefined) {
          return true
        }

        input.position = data.position
      }
    })
  }

}
