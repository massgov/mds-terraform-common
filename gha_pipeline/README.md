Github Actions Pipeline
=======================

This Terraform module configures an AWS role that is assumable by Github Actions in order to handle deployment pipelines that create/modify AWS resources.

Once the pipeline has been configured, a Github Action can be written that pulls in credentials like so:

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    role-to-assume: arn:aws:iam::12345:role/my-project-actions-role
    aws-region: us-east-1
```