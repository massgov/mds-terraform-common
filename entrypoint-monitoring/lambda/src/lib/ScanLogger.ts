const logLevelNumbers: Record<LogLevel, number> = {
  debug: 1,
  log: 2,
  error: 3,
}

export type LogLevel = 'debug'|'log'|'error'

export default class ScanLogger {

  protected entries: [LogLevel, any[]][] = []

  protected minLevel: LogLevel

  protected minLevelNumber: number

  constructor(minLevel: LogLevel = 'log') {
    this.minLevel = minLevel
    this.minLevelNumber = logLevelNumbers[minLevel]
  }

  createChildLogger(): ScanLogger {
    return new ScanLogger(this.minLevel)
  }

  protected add(level: LogLevel, args: any[]) {
    const levelNumber = logLevelNumbers[level]
    if (levelNumber < this.minLevelNumber) {
      return
    }

    this.entries.push([level, args])
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

  dump() {
    for (const [type, args] of this.entries) {
      console[type](...args)
    }
    this.entries = [];
  }
}
