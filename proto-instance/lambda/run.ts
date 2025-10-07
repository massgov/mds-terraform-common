import { handler } from ".";

handler(
  {
    id: "",
    version: "",
    account: "",
    time: "",
    region: "us-east-1",
    resources: [],
    source: "",
    "detail-type": "Scheduled Event",
    detail: {
      force: true
    },
  },
  {
    callbackWaitsForEmptyEventLoop: false,
    functionName: "",
    functionVersion: "",
    invokedFunctionArn: "arn:aws:lambda:us-east-2:123456789012:function:my-function:1",
    memoryLimitInMB: "",
    awsRequestId: "12345",
    logGroupName: "",
    logStreamName: "",
    getRemainingTimeInMillis: function (): number {
      throw new Error("Function not implemented.");
    },
    done: function (error?: Error, result?: any): void {
      throw new Error("Function not implemented.");
    },
    fail: function (error: Error | string): void {
      throw new Error("Function not implemented.");
    },
    succeed: function (messageOrObject: any): void {
      throw new Error("Function not implemented.");
    },
  },
  () => {}
);
