import { handler } from "./index";

const run = async () => {
  process.env.RDS_INSTANCE_IDENTIFIER = process.env.RDS_INSTANCE_IDENTIFIER ?? 'itd-pr-pdg-reportingdata';
  await handler(
    { dryRun: true },
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

run();