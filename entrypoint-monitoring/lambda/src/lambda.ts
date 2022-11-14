import scanner from "./scanner";
import EnvConfigBuilder from "./lib/EnvConfigBuilder";
import ScanReportFormatter from "./lib/ScanReportFormatter";
import SnsNotifier from "./lib/SnsNotifier";
import {SNSClient} from "@aws-sdk/client-sns";

export default async function lambda() {
  const configBuilder = new EnvConfigBuilder()
  const config = configBuilder.build()

  const interconnections = await scanner(config)
  const orphanPoints = interconnections.getOrphanPoints()
  if (!orphanPoints.length) {
    console.log('==== No orphan points found. ====')
    return;
  }

  console.log(`==== Found ${orphanPoints.length} orphan point(s). ====`)

  console.log(`==== Sending the report to the SNS topic... ====`)
  const reportFormatter = new ScanReportFormatter()
  const report = reportFormatter.formatOrphanPoints(interconnections)

  const snsClient = new SNSClient({region: config.region})
  const notifier = new SnsNotifier(snsClient, config)
  await notifier.send(report)
  console.log(`==== The report was sent to the SNS topic. ====`)
}
