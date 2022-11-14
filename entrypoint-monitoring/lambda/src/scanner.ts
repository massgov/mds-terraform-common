import {CloudFrontClient} from "@aws-sdk/client-cloudfront";
import DistributionScanner from "./lib/scanner/DistributionScanner";
import {Route53Client, RRType} from "@aws-sdk/client-route-53";
import Route53Scanner from "./lib/scanner/Route53Scanner";
import Interconnections from "./lib/Interconnections";
import {APIGatewayClient} from "@aws-sdk/client-api-gateway";
import RestApiGatewayScanner from "./lib/scanner/RestApiGatewayScanner";
import {S3Client} from "@aws-sdk/client-s3";
import S3Scanner from "./lib/scanner/S3Scanner";
import {ElasticLoadBalancingV2Client} from "@aws-sdk/client-elastic-load-balancing-v2";
import LoadBalancerScanner from "./lib/scanner/LoadBalancerScanner";
import {ApiGatewayV2Client} from "@aws-sdk/client-apigatewayv2";
import HttpApiGatewayScanner from "./lib/scanner/HttpApiGatewayScanner";
import Config from "./types/Config";
import ScanLogger from "./lib/ScanLogger";
import AllowListScanner from "./lib/scanner/AllowListScanner";
import {SSMClient} from "@aws-sdk/client-ssm";

export default async function(config: Config) {
  const region = config.region;

  const interconnections = new Interconnections()
  const logger = new ScanLogger(config.minLogLevel)
  const scans: Promise<any>[] = []

  const ignoredTypes = new Set<RRType>(['NS', 'SOA', 'TXT', 'CAA', 'MX'])
  const r53Client = new Route53Client({region})
  const r53Scanner = new Route53Scanner(r53Client, ignoredTypes, logger.createChildLogger())
  scans.push(r53Scanner.scan(interconnections))

  const cfClient = new CloudFrontClient({region})
  const distScanner = new DistributionScanner(cfClient, logger.createChildLogger())
  scans.push(distScanner.scan(interconnections))

  const restApiClient = new APIGatewayClient({region})
  const restApiScanner = new RestApiGatewayScanner(restApiClient, logger.createChildLogger())
  scans.push(restApiScanner.scan(interconnections))

  const httpApiClient = new ApiGatewayV2Client({region})
  const httpApiScanner = new HttpApiGatewayScanner(httpApiClient, logger.createChildLogger())
  scans.push(httpApiScanner.scan(interconnections))

  const lbClient = new ElasticLoadBalancingV2Client({region})
  const lbScanner = new LoadBalancerScanner(lbClient, logger.createChildLogger())
  scans.push(lbScanner.scan(interconnections))

  const s3Client = new S3Client({region})
  const s3Scanner = new S3Scanner(s3Client, logger.createChildLogger())
  scans.push(s3Scanner.scan(interconnections))

  const ssmClient = new SSMClient({region})
  const allowedListScanner = new AllowListScanner(ssmClient, config, logger.createChildLogger())
  scans.push(allowedListScanner.scan(interconnections))

  await Promise.all(scans)

  return interconnections
}
