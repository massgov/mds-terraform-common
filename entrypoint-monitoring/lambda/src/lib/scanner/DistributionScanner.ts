import {
  CloudFrontClient,
  DistributionSummary,
  ListDistributionsCommand,
  ListDistributionsCommandInput,
  ListDistributionsCommandOutput
} from "@aws-sdk/client-cloudfront";
import Interconnections from "../Interconnections";
import {ServiceType} from "../../types/Service";
import getPaginated from "../util/getPaginated";
import Scanner from "../../types/Scanner";
import BaseScanner from "./BaseScanner";
import ScanLogger from "../ScanLogger";

export default class DistributionScanner extends BaseScanner implements Scanner {

  serviceType: ServiceType = "cloudfront"

  client: CloudFrontClient;

  constructor(
    client: CloudFrontClient,
    logger: ScanLogger
  ) {
    super(logger)

    this.client = client
  }

  protected async doScan(interconnections: Interconnections) {
    this.logger.log('==== Scanning CloudFront Distributions... ====')

    for await (const summary of this.getDistributionSummaries()) {
      if (!summary.Enabled) {
        continue;
      }

      this.logger.debug(`- Distribution: ${summary.Id} (${summary.DomainName}) `);

      const serviceId = summary.Id
      if (serviceId === undefined) {
        this.logger.error(`CloudFront distribution without an ID!`)
        continue;
      }

      if (summary.DomainName === undefined) {
        this.logger.error(`CloudFront distribution without a domain name!`)
        continue;
      }

      interconnections.addPointToServiceLink(
        summary.DomainName,
        this.serviceType,
        serviceId
      )

      const origins = summary.Origins?.Items;
      if (origins) {
        for (const origin of origins) {
          if (origin.DomainName === undefined) {
            this.logger.error(`CloudFront distribution origin without a domain name: ${summary.Id}!`)
            continue;
          }

          interconnections.addServiceToPointLink(
            this.serviceType,
            serviceId,
            origin.DomainName
          )

          this.logger.debug(`-- Origin: ${origin.DomainName}`);
        }
      }
      else {
        this.logger.debug('-- No Origins');
      }
    }

    console.log('==== The CloudFront Distribution scan is complete. ====')
  }

  async* getDistributionSummaries(): AsyncGenerator<DistributionSummary> {
    const limit = 50;
    const CommandClass = ListDistributionsCommand;

    const input: ListDistributionsCommandInput = {
      MaxItems: limit,
    }

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: ListDistributionsCommandOutput) {
        const distributionSummaries = data.DistributionList?.Items
        if (!distributionSummaries) {
          throw new Error('Unable to list CloudFront distributions.')
        }
        for (const distSummary of distributionSummaries) {
          yield distSummary
        }

        if (!data.DistributionList?.IsTruncated) {
          return true;
        }

        input.Marker = data.DistributionList.NextMarker
      }
    })
  }

}
