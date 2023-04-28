import assert from "assert";
import { Handler, ScheduledEvent } from "aws-lambda";
import { LocalDateTime, DateTimeFormatter} from '@js-joda/core';
import RDS, { CreateDBSnapshotMessage } from "aws-sdk/clients/rds";

const rds = new RDS();

type RunOpts = {
  dryRun?: boolean;
};
type Event = Partial<ScheduledEvent> & RunOpts;

const handler: Handler<Event> = async (event: Event) => {
  assert(process.env.RDS_INSTANCE_IDENTIFIER);

  const snapshotTimeStamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
  const instanceIds = [process.env.RDS_INSTANCE_IDENTIFIER];

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
      return event.dryRun
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