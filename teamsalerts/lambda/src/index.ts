import assert from 'assert';
import { EventBridgeHandler, Handler, SNSHandler } from 'aws-lambda';
import { TopicMap } from './types';

const handler: SNSHandler = async function(event, context, callback) {
    assert(process.env.TOPIC_MAP && typeof process.env.TOPIC_MAP === 'string');
    const topicMap = <TopicMap>JSON.parse(process.env.TOPIC_MAP);
    // // Special handling for formatting ClamAV alert subject and message.
    // data.Records.forEach(function(element, index) {
    //     if (element.Sns.TopicArn.includes('massgov-clamav-scan-status')) {
    //         const message = JSON.parse(element.Sns.Message);
    //         let output = ' ';
    //         for (const [key, value] of Object.entries(message)) {
    //             output += "*" + key + "*: " + value + "\n";
    //         }
    //         data.Records[index].Sns.Subject = 'ClamAV detected an infected file';
    //         data.Records[index].Sns.Message = output;
    //     }
    // });

    // const messages = data.Records.map(record => {
    //     return publisher.publish(record);
    // })
    // return Promise.all(messages)
}

export {
  handler
}