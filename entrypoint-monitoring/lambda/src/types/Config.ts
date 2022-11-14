import {LogLevel} from "../lib/ScanLogger";

export default interface Config {

  region: string

  allowedPointsParamName: string

  minLogLevel: LogLevel

  reportSnsTopic: string

}
