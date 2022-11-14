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
        return `'${id}' Load Balancer`

      case "s3":
        return `'${id}' S3 Bucket`

      case "cloudfront":
        return `'${id}' CloudFront Distribution`

      case "route53":
        return `'${id}' Route53 Record Set`

      case "restapi":
        return `'${id}' REST API Gateway`

      case "httpapi":
        return `'${id}' HTTP API Gateway`

      default:
        return `'${id}' ${type}`
    }
  }

  formatOrphanPoints(interconnections: Interconnections): string {
    const result: string[] = []

    for (const point of interconnections.getOrphanPoints()) {
      result.push(`* '${point.name}' linked from the following services:`)

      // @todo Implement recursive formatting of the whole chain.
      for (const service of Array.from(point.sources.map.values())) {
        result.push(`  * ${this.formatService(service)}`)
      }
    }

    return result.join("\n");
  }

}