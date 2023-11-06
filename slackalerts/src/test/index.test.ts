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
    const events: Array<SNSEvent> = [
        {
            "Records": [
                {
                    "EventSource": "aws:sns",
                    "EventVersion": "1.0",
                    "EventSubscriptionArn": "arn:aws:sns:us-east-1:123456789012:ExampleTopic",
                    "Sns": {
                        "Type": "Notification",
                        "MessageId": "e849714b-6b3f-4802-9575-bf4b894d7e92",
                        "TopicArn": "arn:aws:sns:us-east-1:123456789012:my-cool-topic",
                        "Subject": "subject",
                        "Message": 'message',
                        "Timestamp": "1970-01-01T00:00:00.000Z",
                        "SignatureVersion": "1",
                        "Signature": "EXAMPLE",
                        "SigningCertUrl": "EXAMPLE",
                        "UnsubscribeUrl": "EXAMPLE",
                        "MessageAttributes": {}
                    }
                }
            ]
        },
        {
            "Records": [
                {
                    "EventSource": "aws:sns",
                    "EventVersion": "1.0",
                    "EventSubscriptionArn": "arn:aws:sns:us-east-1:123456789012:ExampleTopic",
                    "Sns": {
                        "Type": "Notification",
                        "MessageId": "95df01b4-ee98-5cb9-9903-4c221d41eb5e",
                        "TopicArn": "arn:aws:sns:us-east-1:123456789012:massgov-clamav-scan-status",
                        "Subject": "Clam AV test",
                        "Message": JSON.stringify({ Foo: "Bar", Bar: "Baz" }),
                        "Timestamp": "1970-01-01T00:00:00.000Z",
                        "SignatureVersion": "1",
                        "Signature": "EXAMPLE",
                        "SigningCertUrl": "EXAMPLE",
                        "UnsubscribeUrl": "EXAMPLE",
                        "MessageAttributes": {}
                    }
                }
            ]
        }
    ]

    it.each(events)('correctly transforms the SNS event', async (event): Promise<void> => {
        await handler(
            event,
            context,
            () => {}
        );
        expect(mockMessage).toMatchSnapshot();
    });
})