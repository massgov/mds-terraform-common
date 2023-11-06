process.env.SLACK_TOKEN = '000000aa-aaaa-cccc-aaaa-bbbbbbbbbb00';
process.env.TOPIC_MAP = JSON.stringify([
  {
    topic_arn: 'arn:aws:sns:us-east-1:123456789012:my-cool-topic',
    icon_emoji: ':robot:',
    channel: '#my-cool-alerts',
    username: '@mds-ssr'
  }
]);
process.env.DEFAULT_CHANNEL = '#alerts';
