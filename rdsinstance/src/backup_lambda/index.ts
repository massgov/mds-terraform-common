import assert from "assert";
import { Handler, ScheduledEvent } from "aws-lambda";
import { LocalDateTime, DateTimeFormatter} from '@js-joda/core';
import RDS, { CreateDBSnapshotMessage } from "aws-sdk/clients/rds";

const rds = new RDS();

type RunOpts = {
  dryRun?: boolean;
  rdsIdentifier?: string
};
type Event = Partial<ScheduledEvent> & RunOpts;

const handler: Handler<Event> = async (event: Event) => {
  const identifier = event.rdsIdentifier ?? process.env.RDS_INSTANCE_IDENTIFIER;
  assert(
    identifier,
    "Must specify a DB instance via the Lambda event body or env['RDS_INSTANCE_IDENTIFIER']"
  );

  const dryRun = event.dryRun ?? false;
  const snapshotTimeStamp = LocalDateTime.now().format(
    DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH-mm-ss")
  );
  const instanceIds = [identifier];

  const params: Array<CreateDBSnapshotMessage> = instanceIds.map(
    (instanceId) => {
      assert(instanceId);
      return {
        DBInstanceIdentifier: instanceId,
        DBSnapshotIdentifier: `${instanceId}-${snapshotTimeStamp}-snapshot`
      };
    }
  );

  return Promise.all(
    params.map((param) => {
      return dryRun
        ? console.log(
            `CreateDBSnapshotMessage: ${JSON.stringify(param)}`
          )
        : rds.createDBSnapshot(param).promise();
    })
  );
};

export {
  handler
};