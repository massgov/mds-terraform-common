#!/usr/bin/env sh

# Use credentials directly...
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
npx ts-node src/cli.ts

# ... OR use AWS-Vault (recommended):
aws-vault exec ... -- npx ts-node src/cli.ts
