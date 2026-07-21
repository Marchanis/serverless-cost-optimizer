output "lambda_function_arn" {
    description = "the ARN of the cost optimizer Lambda function"
    value = aws_lambda_function.lambda_function.arn
  
}

output "sns_topic_arn" {
  description = "the ARN of the SNS topic for cost alerts"
  value = aws_sns_topic.sns_topic.arn
}

output "eventbridge_scheduler_arn" {
    description = "the ARN of the EventBridge schedule"
    value = aws_scheduler_schedule.weekly_schedule.arn
}