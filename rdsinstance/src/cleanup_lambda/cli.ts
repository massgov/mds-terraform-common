import assert from "assert";
import { handler } from "./index";

const run = async (rdsIdentifier: string) => {
  await handler(
    { dryRun: true, rdsIdentifier },
    {
      callbackWaitsForEmptyEventLoop: false,
      functionName: "",
      functionVersion: "",
      invokedFunctionArn: "",
      memoryLimitInMB: "",
      awsRequestId: "",
      logGroupName: "",
      logStreamName: "",
      getRemainingTimeInMillis: () => 300,
      done: () => console.log('done'),
      fail: () => console.error('fail'),
      succeed: () => console.log('success'),
    },
    () => console.log("done")
  );
};

if (require.main === module) {
  const identifier = process.argv[2];
  assert(
    typeof identifier === 'string',
    'Usage: npx ts-node cleanup_lambda/cli.ts <rds_db_identifier>'
  );
  run(identifier);
}