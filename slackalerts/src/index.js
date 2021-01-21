const {SNSSlackPublisher} = require('@lastcall/sns-slack-alerts-consumer');
const {SLACK_TOKEN, DEFAULT_CHANNEL, TOPIC_MAP} = process.env;

// Slack message settings for topics that don't have a special setting:
const defaultMessage = {
    as_user: true,
    channel: DEFAULT_CHANNEL
}

// Map of special topics to slack message bodies:
// Map of special topics to slack message bodies:
let topicMap = [];
JSON.parse(TOPIC_MAP).forEach(item => {
    topicMap[item.topic_arn] = {
        username: item.username,
        icon_emoji: item.icon_emoji,
        as_user: false,
        channel: item.channel
    };
});

console.log(topicMap);

const publisher = new SNSSlackPublisher(SLACK_TOKEN, defaultMessage, topicMap);

exports.handler = async function(data, context, callback) {

    // Special handling for formatting ClamAV alert subject and message.
    data.Records.forEach(function(element, index) {
        if (element.Sns.TopicArn.includes('massgov-clamav-scan-status')) {
            const message = JSON.parse(element.Sns.Message);
            let output = ' ';
            for (const [key, value] of Object.entries(message)) {
                output += "*" + key + "*: " + value + "\n";
            }
            data.Records[index].Sns.Subject = 'ClamAV detected an infected file';
            data.Records[index].Sns.Message = output;
        }
    });

    const messages = data.Records.map(record => {
        return publisher.publish(record);
    })
    return Promise.all(messages)
}


