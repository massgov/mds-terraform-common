import ScanLogger from "../ScanLogger";
import Interconnections from "../Interconnections";

export default abstract class BaseScanner {

  protected logger: ScanLogger

  constructor(logger: ScanLogger) {
    this.logger = logger
  }

  protected abstract doScan(interconnections: Interconnections): Promise<any>

  async scan(interconnections: Interconnections) {
    await this.doScan(interconnections)
    this.logger.dump()
  }

}