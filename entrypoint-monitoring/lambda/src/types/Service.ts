import {PointList} from "./Point";

export type ServiceType = 'cloudfront'|'route53'|'restapi'|'httpapi'|'loadbalancer'|'s3'|'allowed'

export default interface Service {

  type: ServiceType

  id: string

  sources: PointList

}
