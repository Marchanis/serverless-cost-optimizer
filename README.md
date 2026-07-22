# Serverless Cost Optimizer

A Lambda function that scans AWS weekly for resources quietly costing money — stopped EC2 instances, unattached EBS volumes, unused Elastic IPs — and emails a report. Deployed entirely with Terraform, including remote state.

## What it checks

- EC2 instances stopped for 30+ days
- EBS volumes not attached to anything
- Elastic IPs not associated with anything
- Last 30 days of EC2 compute cost (Cost Explorer API)

Runs every Monday at 9am via EventBridge, publishes results to SNS.

## Architecture

```
EventBridge (weekly cron)
    -> Lambda -> EC2 API + Cost Explorer API
    -> SNS -> email
```

IAM is scoped to least privilege: the Lambda's role only has read-only EC2/CloudWatch access plus two specific permissions (publish to one SNS topic, read Cost Explorer). EventBridge has its own separate role, allowed only to invoke this one function.

## Stack

Lambda (Python 3.11) · EventBridge Scheduler · SNS · Cost Explorer API · Terraform (S3 remote state, S3-native locking)

## Why Lambda over EC2

The check takes seconds and runs once a week — running a server 24/7 for that would mean paying for idle compute and maintaining an OS for no reason. Lambda only bills for the seconds it runs.

## Repo layout

```
backend.tf / provider.tf / variables.tf
iam.tf             - Lambda's execution role
lambda.tf          - function + packaging
sns.tf             - topic + subscription
eventbridge.tf     - schedule + its own IAM role
outputs.tf
lambda/lambda_function.py
```

The S3 state bucket is created separately, in a small one-time bootstrap config (not in this repo) — it has to exist before this project's backend can point at it.

## Running it

```
terraform init
terraform plan
terraform apply
```

Set `sns_email` in `terraform.tfvars` first, and confirm the SNS subscription email before alerts will arrive.

## Example output

```json
{
  "IdleInstances": [
    { "InstanceId": "i-041e403cd697a1bbf", "DaysStopped": 75 }
  ],
  "UnusedVolumes": [],
  "UnusedAddresses": [],
  "TotalEC2CostLast30Days": 0.0
}
```
