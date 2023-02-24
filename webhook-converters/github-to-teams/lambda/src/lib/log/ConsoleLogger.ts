import { LogLevel } from "./LogLevel";

const logLevelNumbers: Record<LogLevel, number> = {
  debug: 1,
  log: 2,
  error: 3,
}

export default class ConsoleLogger {

  protected minLevel: LogLevel

  protected minLevelNumber: number

  constructor(minLevel: LogLevel = 'log') {
    this.minLevel = minLevel
    this.minLevelNumber = logLevelNumbers[minLevel]
  }

  protected add(level: LogLevel, args: any[]) {
    const levelNumber = logLevelNumbers[level]
    if (levelNumber < this.minLevelNumber) {
      return
    }

    console[level](...args)
  }

  log(...args: any) {
    this.add('log', args)
  }

  debug(...args: any) {
    this.add('debug', args)
  }

  error(...args: any) {
    this.add('error', args)
  }
}
