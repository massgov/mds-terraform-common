import ServiceList from "../lib/ServiceList";

export default interface Point {
  name: string
  destinations: ServiceList
  sources: ServiceList
}

export type PointList = Map<string, Point>
