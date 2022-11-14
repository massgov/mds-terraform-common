import {PointList} from "./Point";

export type ServiceType = 'cloudfront'|'route53'|'restapi'|'httpapi'|'loadbalancer'|'s3'|'allowed'

/**
 * Represents a service.
 *
 * It's the AWS service that either links to a point
 */
export default interface Service {

  type: ServiceType

  /**
   * The service ID.
   *
   * It must be unique within the same type.
   */
  id: string

  /**
   * The list of points that resolve to this service.
   *
   * For example, it's an auto-generated domain name of the CloudFront distribution.
   */
  sources: PointList

}
