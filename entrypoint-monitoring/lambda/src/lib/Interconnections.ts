import Service, {ServiceType} from "../types/Service";
import Point, {PointList} from "../types/Point";
import ServiceList from "./ServiceList";

export default class Interconnections {

  points: PointList = new Map()

  services: ServiceList = new ServiceList()

  protected getPoint(name: string): Point {
    if (this.points.has(name)) {
      return this.points.get(name) as Point
    }

    const result: Point = {
      name,
      destinations: new ServiceList(),
      sources: new ServiceList(),
    }
    this.points.set(name, result)
    return result
  }

  protected getService(type: ServiceType, id: string): Service {
    if (this.services.has(type, id)) {
      return this.services.get(type, id) as Service
    }

    const result: Service = {
      type,
      id,
      sources: new Map()
    }
    this.services.add(result)
    return result
  }

  addServiceToPointLink(serviceType: ServiceType, serviceId: string, pointName: string) {
    const service = this.getService(serviceType, serviceId)
    const point = this.getPoint(pointName)
    point.sources.add(service)
  }

  addPointToServiceLink(pointName: string, serviceType: ServiceType, serviceId: string) {
    const service = this.getService(serviceType, serviceId)
    const point = this.getPoint(pointName)
    point.destinations.add(service)
    service.sources.set(point.name, point)
  }

  getOrphanPoints(): Point[] {
    return Array.from(this.points.values())
      .filter((point) => !point.destinations.isEmpty())
  }

  hasOrphanPoints(): boolean {
    return Array.from(this.points.values())
      .some((point) => !point.destinations.isEmpty())
  }

}
