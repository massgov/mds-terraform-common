import {
  Bucket,
  GetBucketLocationCommand,
  GetBucketWebsiteCommand,
  GetBucketWebsiteCommandOutput,
  HeadBucketCommand,
  ListBucketsCommand,
  ListBucketsCommandInput,
  ListBucketsCommandOutput,
  S3Client,
  WebsiteConfiguration,
  _Error,
} from "@aws-sdk/client-s3";
import Interconnections from "../Interconnections";
import getPaginated from "../util/getPaginated";
import {ServiceType} from "../../types/Service";
import Scanner from "../../types/Scanner";
import ScanLogger from "../ScanLogger";
import BaseScanner from "./BaseScanner";

export default class S3Scanner extends BaseScanner implements Scanner {

  client: S3Client

  serviceType: ServiceType = "s3"

  constructor(
    client: S3Client,
    logger: ScanLogger
  ) {
    super(logger)

    this.client = client
  }

  protected async tryGetBucketRegion(bucketName: string): Promise<string | null> {
    try {
      const headBucketResult = await this.client.send(
        new GetBucketLocationCommand({
          Bucket: bucketName
        })
      )
      return headBucketResult.LocationConstraint ?? null;
    } catch (e) {
      if ((e as _Error).Code === 'AccessDenied') {
        this.logger.error(`Insufficient permissions to get ${bucketName} bucket location`);
      } else {
        this.logger.error([bucketName, e]);
      }
    }
    return null;
  }

  protected async doScan(interconnections: Interconnections) {
    this.logger.log('==== Scanning S3 Buckets... ====')

    const defaultRegion = await this.client.config.region()
    const requestPromises: Promise<any>[] = [];
    for await (const bucket of this.getBuckets()) {
      const bucketName = bucket.Name
      if (bucketName === undefined) {
        this.logger.error(`Bucket without a name!`);
        continue;
      }
      const bucketRegion = await this.tryGetBucketRegion(bucketName) ?? defaultRegion;

      this.logger.debug(`- ${bucketName} bucket.`)

      // CloudFront links to an S3 bucket the following way.
      const cfOriginPoints = [
        `${bucketName}.s3.${bucketRegion}.amazonaws.com`,
        `${bucketName}.s3.amazonaws.com` // S3 origins are sometimes missing the region in CF
      ];
      cfOriginPoints.forEach((cfOriginPoint) => {
        interconnections.addPointToServiceLink(
          cfOriginPoint,
          this.serviceType,
          bucketName
        );
        this.logger.debug(`-- CF-specific entrypoint: ${cfOriginPoint}`);
      });

      const websiteConfigPromise = this.getBucketWebsiteConfig(bucketName)
        .then((websiteConfig: WebsiteConfiguration|undefined) => {
          this.doScanBucketWebsiteConfig(
            bucketRegion,
            bucketName,
            websiteConfig,
            interconnections
          )
        })
      requestPromises.push(websiteConfigPromise)
    }

    // Wait until all the requests complete.
    await Promise.all(requestPromises)

    this.logger.log('==== The S3 Buckets scan is complete. ====')
  }

  protected doScanBucketWebsiteConfig(
    region: string,
    bucketName: string,
    websiteConfig: WebsiteConfiguration|undefined,
    interconnections: Interconnections
  ) {
    if (websiteConfig === undefined) {
      this.logger.debug(`- No website config for the ${bucketName} bucket.`)
      return;
    }

    this.logger.debug(`- Website config of the ${bucketName} bucket:`)

    // Existence of the website configuration means that the bucket is
    // accessible through a few more points.
    // See https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteEndpoints.html
    const websiteEndpoints = [
      `${bucketName}.s3-website.${region}.amazonaws.com`,
      `${bucketName}.s3-website-${region}.amazonaws.com`,
    ];
    for (const websiteEndpoint of websiteEndpoints) {
      interconnections.addPointToServiceLink(
        websiteEndpoint,
        this.serviceType,
        bucketName
      )
      this.logger.debug(`-- Website entrypoint: ${websiteEndpoint}`)
    }

    // The website config could define an unconditional redirect to another
    // point.
    const redirectHostname = websiteConfig.RedirectAllRequestsTo?.HostName
    if (redirectHostname) {
      interconnections.addServiceToPointLink(
        this.serviceType,
        bucketName,
        redirectHostname
      )
      this.logger.debug(`-- Unconditional redirect to ${redirectHostname}`)
    }

    // The website config could also define a set of routing rules that also
    // redirects to another point.
    if (websiteConfig.RoutingRules?.length) {
      this.logger.debug(`-- Routing rules.`)
      for (const routingRule of websiteConfig.RoutingRules) {
        const ruleHostname = routingRule.Redirect?.HostName
        if (!ruleHostname) {
          continue;
        }

        interconnections.addServiceToPointLink(
          this.serviceType,
          bucketName,
          ruleHostname
        )
        this.logger.debug(`--- Routing rule target: ${ruleHostname}`)
      }
    }
  }

  protected async getBucketWebsiteConfig(
    bucketName: string
  ): Promise<WebsiteConfiguration | undefined> {
    const command = new GetBucketWebsiteCommand({
      Bucket: bucketName
    })

    let data: GetBucketWebsiteCommandOutput | undefined = undefined;
    try {
      data = await this.client.send(command)
    }
    catch (e: any) {
      if (e.name === 'NoSuchWebsiteConfiguration') {
        return undefined
      }

      // @todo Support for buckets in other regions (the PermanentRedirect error indicates those).
      if (e.name === 'PermanentRedirect') {
        this.logger.log(`The ${bucketName} bucket belongs to a different region.`)
        return undefined
      }

      if (e.name === 'AccessDenied') {
        this.logger.error(`Not enough permissions to read website config of the ${bucketName} bucket website config.`)
        return undefined
      }

      throw e;
    }

    const {
      $metadata: metadata,
      ...result
    } = data
    if (data.$metadata.httpStatusCode !== 200) {
      return undefined
    }

    return result
  }

  protected async* getBuckets(): AsyncGenerator<Bucket> {
    const CommandClass = ListBucketsCommand;
    const input: ListBucketsCommandInput = {}

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: ListBucketsCommandOutput) {
        const buckets = data.Buckets || []
        for (const bucket of buckets) {
          yield bucket
        }

        return true;
      }
    })
  }

}