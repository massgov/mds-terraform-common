import Interconnections from "./Interconnections";
import Service from "../types/Service";

export default class ScanReportFormatter {

  protected formatService(service: Service): string {
    const {
      type,
      id
    } = service


    switch (type) {
      case "loadbalancer":
        return `${id} Load Balancer`

      case "s3":
        return `${id} S3 Bucket`

      case "cloudfront":
        return `${id} CloudFront Distribution`

      case "route53":
        return `${id} Route53 Record Set`

      case "restapi":
        return `${id} REST API Gateway`

      case "httpapi":
        return `${id} HTTP API Gateway`

      default:
        return `${id} ${type}`
    }
  }

  formatOrphanPoints(interconnections: Interconnections): string {
    const result: string[] = []

    for (const point of interconnections.getOrphanPoints()) {
      result.push(`➤ ${point.name} is pointed by the following resources:`)

      // @todo Implement recursive formatting of the whole chain.
      for (const service of Array.from(point.sources.map.values())) {
        result.push(`  ■ ${this.formatService(service)}`)
      }
    }

    if (result.length) {
      result.unshift(
        'Hello,',
        '',
        "The following unknown entrypoints were found in the AWS account. The best way to resolve this alert is to re-configure or delete the services that point to each of the entrypoints. If they're valid external ones, they must be added to the allowlist.",
        ''
      )
    }

    return result.join("\n");
  }

}