import assert from "assert";
import { Handler, ScheduledEvent } from "aws-lambda";
import { AnyIterable, filter, pipeline, tap, consume } from "streaming-iterables";
import { ZonedDateTime, nativeJs, Duration, ZoneId } from '@js-joda/core';
import RDS, { DeleteDBSnapshotResult, DBSnapshot, DBSnapshotMessage } from "aws-sdk/clients/rds";

const rds = new RDS();

const RETENTION_PERIOD_DAYS = 90;

type RunOpts = {
  dryRun?: boolean;
  rdsIdentifier?: string;
};
type Event = Partial<ScheduledEvent> & RunOpts;

const handler: Handler<Event> = async (event: Event) => {
  const identifier = event.rdsIdentifier ?? process.env.RDS_INSTANCE_IDENTIFIER;
  assert(
    identifier,
    "Must specify a DB instance via the Lambda event body or env['RDS_INSTANCE_IDENTIFIER']"
  );

  const dryRun = event.dryRun ?? false;
  const instanceIds = [identifier];

  await pipeline(
    () => instanceIds,
    getSnapshots,
    isOlderThanRetentionPeriod,
    tap(
      (snapshot) => {
        if (snapshot.SnapshotCreateTime) {
          const snapshotAge = Duration.between(
            nativeJs(snapshot.SnapshotCreateTime, ZoneId.UTC),
            ZonedDateTime.now()
          );
          console.log(
            `${snapshot.DBSnapshotIdentifier} is ${snapshotAge.toDays()} day(s) old - deleting`
          );
        }
      }
    ),
    (snapshots) => deleteSnapshots(dryRun, snapshots),
    tap(
      (deleteResult) => deleteResult?.DBSnapshot
        ? console.log(`Successfully cleaned up ${deleteResult.DBSnapshot.DBSnapshotIdentifier}`)
        : undefined
    ),
    consume
  );
};

async function* getSnapshots(instanceIds: AnyIterable<string>): AsyncIterable<DBSnapshot> {
  for await (const instanceId of instanceIds) {
    let marker: string | undefined = undefined;
    do {
      const describeResult: DBSnapshotMessage = await rds
        .describeDBSnapshots({
          DBInstanceIdentifier: instanceId,
          SnapshotType: "manual",
          Marker: marker
        })
        .promise();

      yield * (describeResult.DBSnapshots ?? []);
      marker = describeResult.Marker;
    } while (marker);
  }
}
const isOlderThanRetentionPeriod = filter((snapshot: DBSnapshot) => 
  Boolean(snapshot.SnapshotCreateTime &&
    nativeJs(snapshot.SnapshotCreateTime).isBefore(
      ZonedDateTime.now().minusDays(RETENTION_PERIOD_DAYS)
    )
  )
);

async function* deleteSnapshots(dryRun: boolean, snapshots: AsyncIterable<DBSnapshot>): AsyncIterable<DeleteDBSnapshotResult | null> {
  for await (const snapshot of snapshots) {
    assert(snapshot.DBSnapshotIdentifier);
    const params = {
      DBSnapshotIdentifier: snapshot.DBSnapshotIdentifier,
    };
    let result: DeleteDBSnapshotResult | null = null
    if (dryRun) {
      console.log(`DeleteDBSnapshot Message: ${JSON.stringify(params)}`)
    } else {
      result = await rds.deleteDBSnapshot(params).promise();
    }
    yield result;
  }
}

export {
  handler
};