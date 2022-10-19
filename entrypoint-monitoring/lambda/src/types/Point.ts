import ServiceList from "../lib/ServiceList";

/**
 * Represents a point.
 *
 * The point is a domain name or an IP address.
 */
export default interface Point {

  /**
   * The domain name / IP address.
   */
  name: string

  /**
   * The list of services this point resolves to.
   *
   * For example, a Load Balancer that has this name.
   */
  destinations: ServiceList

  /**
   * The list of services that link to this point.
   *
   * For example, a CloudFront distribution that has this domain name as an origin.
   */
  sources: ServiceList
}

export type PointList = Map<string, Point>
