import Service, {ServiceType} from "../types/Service";

export default class ServiceList {

  readonly map: Map<string, Service> = new Map()

  protected getKey(type: ServiceType, id: string) {
    return `${type}|${id}`
  }

  has(type: ServiceType, id: string): boolean {
    const key = this.getKey(type, id)
    return this.map.has(key)
  }

  get(type: ServiceType, id: string): Service | undefined {
    const key = this.getKey(type, id)
    return this.map.get(key);
  }

  add(service: Service): ServiceList {
    const key = this.getKey(service.type, service.id)
    this.map.set(key, service);
    return this
  }

  isEmpty(): boolean {
    return !!this.map.size
  }

}