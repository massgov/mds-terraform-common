import {
  AliasTarget,
  HostedZone,
  ListHostedZonesCommand,
  ListHostedZonesCommandInput,
  ListHostedZonesCommandOutput,
  ListResourceRecordSetsCommand,
  ListResourceRecordSetsCommandInput,
  ListResourceRecordSetsCommandOutput,
  ResourceRecordSet,
  Route53Client,
  RRType
} from "@aws-sdk/client-route-53";
import Interconnections from "../Interconnections";
import {ServiceType} from "../../types/Service";
import getPaginated from "../util/getPaginated";
import Scanner from "../../types/Scanner";
import ScanLogger from "../ScanLogger";
import BaseScanner from "./BaseScanner";

export default class Route53Scanner extends BaseScanner implements Scanner {

  serviceType: ServiceType = "route53"

  client: Route53Client

  ignoredTypes: Set<RRType|string>

  ignoredCnameTarget: RegExp = /\.(acm-validations\.aws\.|dkim\.amazonses\.com)$/

  constructor(
    client: Route53Client,
    ignoredTypes: Set<RRType|string>,
    logger: ScanLogger
  ) {
    super(logger)

    this.client = client
    this.ignoredTypes = ignoredTypes
  }

  protected normalizeDomainName(raw: string): string {
    return raw.replace(/\.+$/, '')
  }

  protected async doScan(interconnections: Interconnections) {
    this.logger.log('==== Scanning Route53 Record Sets... ====')

    const region = await this.client.config.region()
    const s3AliasTargets = [
      `s3-website.${region}.amazonaws.com`,
      `s3-website-${region}.amazonaws.com`,
    ]

    for await (const zone of this.getHostedZones()) {
      if (!zone.Id) {
        this.logger.error(`Zone without ID!`);
        continue;
      }

      this.logger.debug(`- Zone ${zone.Id} (${zone.Name}) ===`)

      for await (const recordSet of this.getRecordSets(zone.Id)) {
        if (recordSet.Type === undefined) {
          this.logger.error(`Route53 record set without a type!`)
          continue;
        }

        if (this.ignoredTypes.has(recordSet.Type)) {
          this.logger.debug(`-- Ignoring ${recordSet.Name} DNS record set of type ${recordSet.Type}.`)
          continue;
        }

        if (recordSet.Name === undefined) {
          this.logger.error(`Route53 record set without a name!`)
          continue;
        }
        const serviceId = recordSet.Name

        interconnections.addPointToServiceLink(
          this.normalizeDomainName(recordSet.Name),
          this.serviceType,
          serviceId
        )

        this.logger.debug(`-- Record set ${recordSet.Name} `)
        if (recordSet.AliasTarget) {
          this.addAliasLink({
            interconnections,
            serviceId,
            aliasTarget: recordSet.AliasTarget,
            s3AliasTargets
          })
        }
        else if (recordSet.ResourceRecords) {
          for (const record of recordSet.ResourceRecords) {
            if (record.Value === undefined) {
              this.logger.error(`Route53 resource record without a value!`)
              continue;
            }

            // Ignore the certificate validation records.
            if (recordSet.Type === 'CNAME' && this.ignoredCnameTarget.test(record.Value)) {
              this.logger.debug(`---- Ignoring a special CNAME record: ${record.Value}`)
              continue;
            }

            interconnections.addServiceToPointLink(
              this.serviceType,
              serviceId,
              this.normalizeDomainName(record.Value)
            )
            this.logger.debug(`---- ${record.Value}`);
          }
        }
        else {
          this.logger.error(`Unknown record set type!`)
        }
      }
    }

    this.logger.log('==== The Route53 Record Sets scan is complete. ====')
  }

  addAliasLink({
    interconnections,
    serviceId,
    aliasTarget,
    s3AliasTargets
  }: {
    interconnections: Interconnections,
    serviceId: string,
    aliasTarget: AliasTarget,
    s3AliasTargets: string[]
  }): void {
    if (aliasTarget.DNSName === undefined) {
      this.logger.error(`Route53 record set without an alias DNS name!`)
      return;
    }

    const normalizedTargetDnsName = this.normalizeDomainName(aliasTarget.DNSName)

    // Route53 allows directly pointing to S3 Website endpoints. API shows it as
    // an alias record pointing to a website endpoint but without the bucket
    // prefix. We add `bucket.` prefix to them in order to match S3 website
    // endpoints discovered by the S3 scanner.
    for (const s3Target of s3AliasTargets) {
      if (normalizedTargetDnsName === s3Target) {
        const s3BucketEndpoint = `${this.normalizeDomainName(serviceId)}.${s3Target}`

        interconnections.addServiceToPointLink(
          this.serviceType,
          serviceId,
          s3BucketEndpoint
        )
        this.logger.debug(`- S3 website: ${s3BucketEndpoint}`)
        return;
      }
    }

    // Fallback to simply adding the alias target.
    interconnections.addServiceToPointLink(
      this.serviceType,
      serviceId,
      normalizedTargetDnsName
    )
    this.logger.debug(`- ${normalizedTargetDnsName}`)
  }

  async* getHostedZones(): AsyncGenerator<HostedZone> {
    const limit = 20;
    const CommandClass = ListHostedZonesCommand;

    const input: ListHostedZonesCommandInput = {
      MaxItems: limit,
    }

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: ListHostedZonesCommandOutput) {
        const hostedZones = data.HostedZones || []
        for (const hostedZone of hostedZones) {
          yield hostedZone
        }

        if (!data.IsTruncated) {
          return true;
        }

        input.Marker = data.Marker
      }
    })
  }

  async* getRecordSets(hostedZoneId: string): AsyncGenerator<ResourceRecordSet> {
    const limit = 50;
    const CommandClass = ListResourceRecordSetsCommand;

    const input: ListResourceRecordSetsCommandInput = {
      HostedZoneId: hostedZoneId,
      MaxItems: limit,
    }

    yield* getPaginated({
      maxRequests: 20,
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: ListResourceRecordSetsCommandOutput) {
        const recordSets = data.ResourceRecordSets || []
        for (const recordSet of recordSets) {
          yield recordSet
        }

        if (!data.IsTruncated) {
          return true;
        }

        input.StartRecordIdentifier = data.NextRecordIdentifier
        input.StartRecordName = data.NextRecordName
        input.StartRecordType = data.NextRecordType
      }
    })
  }

}