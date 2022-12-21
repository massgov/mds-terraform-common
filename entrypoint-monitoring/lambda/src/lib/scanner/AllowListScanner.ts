import Scanner from "../../types/Scanner";
import Interconnections from "../Interconnections";
import {ServiceType} from "../../types/Service";
import {GetParameterCommand, Parameter, SSMClient} from "@aws-sdk/client-ssm";
import Config from "../../types/Config";
import BaseScanner from "./BaseScanner";
import ScanLogger from "../ScanLogger";

export default class AllowListScanner extends BaseScanner implements Scanner {

  protected client: SSMClient

  protected paramName: string

  protected allowed: string[]|undefined = undefined

  protected serviceType: ServiceType = "allowed"

  constructor(client: SSMClient, config: Config, logger: ScanLogger) {
    super(logger)

    this.client = client
    this.paramName = config.allowedPointsParamName
  }

  async readAllowedList() {
    if (this.allowed !== undefined) {
      return;
    }

    this.logger.debug(`- Reading the list of allowed points from the SSM parameter: ${this.paramName}`)
    const param = await this.getParam(this.paramName)
    if (param === undefined) {
      this.logger.log('The SSM parameter is missing, no points will be manually approved.')
      this.allowed = []
      return;
    }

    const value = param.Value
    if (!value) {
      this.logger.debug('-- The SSM parameter is empty, no points will be manually approved.')
      this.allowed = []
      return;
    }

    this.allowed = value.split(',')
  }

  async getParam(name: string): Promise<Parameter|undefined> {
    try {
      const command = new GetParameterCommand({
        Name: name
      })
      const data = await this.client.send(command)
      if (!data.Parameter) {
        return undefined
      }

      return data.Parameter
    }
    catch (e:any) {
      if (e.name !== 'ParameterNotFound') {
        this.logger.error(e)
        throw e
      }

      return undefined
    }
  }

  protected async doScan(interconnections: Interconnections) {
    this.logger.log('==== Registering the manually allowed points. ====')

    await this.readAllowedList()

    for (const pointName of this.allowed || []) {
      interconnections.addPointToServiceLink(
        pointName,
        this.serviceType,
        pointName
      )
      this.logger.debug(`- Allowed: ${pointName}`)
    }

    this.logger.log('==== Registration of the manually allowed points is complete. ====')
  }

}
