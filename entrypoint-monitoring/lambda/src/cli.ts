import scanner from "./scanner";
import config from "./config";
import ScanReportFormatter from "./lib/ScanReportFormatter";

scanner(config)
  .then((interconnections) => {
    const reportFormatter = new ScanReportFormatter()
    const report = reportFormatter.formatOrphanPoints(interconnections)

    console.log('==== Orphan points: ====')
    console.log(report)
  })
  .catch(e => {
    console.error(e)
  })
