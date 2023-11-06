import { Context, SNSEvent } from 'aws-lambda';
import { handler } from '../index';

let mockMessage: any;

jest.mock('@slack/client', () => {
    return {
        WebClient: jest.fn().mockImplementation(() => {
            return {
                chat: {
                    postMessage: (message: unknown) => { mockMessage = message }
                }
            };
        })
    };
});

beforeEach(() => {
    mockMessage = undefined;
    jest.resetAllMocks();
});

describe('handler', () => {
    const record: SNSEvent = {
        "Records": [
            {
                "EventSource": "aws:sns",
                "EventVersion": "1.0",
                "EventSubscriptionArn": "arn:aws:sns:us-east-1:{{accountId}}:ExampleTopic",
                "Sns": {
                    "Type": "Notification",
                    "MessageId": "95df01b4-ee98-5cb9-9903-4c221d41eb5e",
                    "TopicArn": "arn:aws:sns:us-east-1:123456789012:ExampleTopic",
                    "Subject": "example subject",
                    "Message": "example message",
                    "Timestamp": "1970-01-01T00:00:00.000Z",
                    "SignatureVersion": "1",
                    "Signature": "EXAMPLE",
                    "SigningCertUrl": "EXAMPLE",
                    "UnsubscribeUrl": "EXAMPLE",
                    "MessageAttributes": {
                        "Test": {
                            "Type": "String",
                            "Value": "TestString"
                        },
                        "TestBinary": {
                            "Type": "Binary",
                            "Value": "TestBinary"
                        }
                    }
                }
            }
        ]
    };

    const context: Context = {
        callbackWaitsForEmptyEventLoop: false,
        functionName: '',
        functionVersion: '',
        invokedFunctionArn: '',
        memoryLimitInMB: '',
        awsRequestId: '',
        logGroupName: '',
        logStreamName: '',
        getRemainingTimeInMillis: () => 0,
        done: () => {},
        fail: () => {},
        succeed: () => {}
    };

    it('correctly transforms the SNS event(s)', async (): Promise<void> => {
        await handler(
            record,
            context,
            () => {}
        );
        expect(mockMessage).toMatchSnapshot();
    });
})