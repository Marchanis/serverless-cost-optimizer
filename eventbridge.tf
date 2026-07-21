resource "aws_scheduler_schedule" "weekly_schedule" {
    name = "cost-optimizer-weekly-schedule"
    description = "weekly schedule to trigger the Lambda function"
    group_name = "default"

    schedule_expression = "cron(0 9 ? * MON *)"
    schedule_expression_timezone = "Africa/Casablanca"

    flexible_time_window {
        mode = "OFF"
    }

    target {
        arn = aws_lambda_function.lambda_function.arn
        input = jsonencode({
            "message" = "Triggering the Lambda function from EventBridge"
        })
        role_arn = aws_iam_role.scheduler_role.arn
        
    }

}


resource "aws_iam_role" "scheduler_role" {
    name = "cost_optimizer_scheduler_role"
    assume_role_policy = jsonencode ({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"

                Effect = "Allow"
                Principal = {
                    Service = "scheduler.amazonaws.com"
                }
            }  
        ]  

    })
    
}

resource "aws_iam_role_policy" "scheduler_invoke_policy" {
    name = "scheduler-invoke-lambda-permission"
    role = aws_iam_role.scheduler_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "lambda:InvokeFunction"
                ]
                Effect   = "Allow"
                Resource = aws_lambda_function.lambda_function.arn
            },
        ]
    })
}