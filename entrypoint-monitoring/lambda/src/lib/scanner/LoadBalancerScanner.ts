import {
  DescribeLoadBalancersCommand,
  DescribeLoadBalancersCommandInput,
  DescribeLoadBalancersCommandOutput,
  ElasticLoadBalancingV2Client, LoadBalancer
} from "@aws-sdk/client-elastic-load-balancing-v2";
import {ServiceType} from "../../types/Service";
import Interconnections from "../Interconnections";
import getPaginated from "../util/getPaginated";
import Scanner from "../../types/Scanner";
import ScanLogger from "../ScanLogger";
import BaseScanner from "./BaseScanner";

export default class LoadBalancerScanner extends BaseScanner implements Scanner {

  client: ElasticLoadBalancingV2Client

  serviceType: ServiceType = "loadbalancer"

  constructor(client: ElasticLoadBalancingV2Client, logger: ScanLogger) {
    super(logger)

    this.client = client
  }

  protected async doScan(interconnections: Interconnections) {
    this.logger.log('==== Scanning load balancers... ====')

    for await (const balancer of this.getLoadBalancers()) {
      const balancerName = balancer.LoadBalancerName
      if (!balancerName) {
        this.logger.error('Found a load balancer without a name!')
        continue;
      }

      this.logger.debug(`- Load balancer (${balancer.Type}): ${balancerName}`)

      const dnsName = balancer.DNSName
      if (!dnsName) {
        this.logger.error('Found a load balancer without a DNS name!')
        continue;
      }

      // The load balancer has default entrypoint.
      interconnections.addPointToServiceLink(
        dnsName,
        this.serviceType,
        balancerName
      )
      this.logger.debug(`-- Entrypoint: ${dnsName}`)
    }

    this.logger.log('==== The load balancer scan is complete. ====')
  }

  async* getLoadBalancers(): AsyncGenerator<LoadBalancer> {
    const limit = 50;
    const CommandClass = DescribeLoadBalancersCommand;

    const input: DescribeLoadBalancersCommandInput = {
      PageSize: limit,
    }

    yield* getPaginated({
      input,
      CommandClass,
      client: this.client,
      logger: this.logger,
      reader: async function*(data: DescribeLoadBalancersCommandOutput) {
        const balancers = data.LoadBalancers || []
        for (const balancer of balancers) {
          yield balancer
        }

        if (data.NextMarker === undefined) {
          return true;
        }

        input.Marker = data.NextMarker
      }
    })
  }

}