resource "aws_iam_role" "lambda_execution_role" {
    name = "serverless-cost-optimizer-lambda-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            },
        ]
    })
   
}

resource "aws_iam_role_policy_attachment" "cloudwatch_readonly" {
    role       = aws_iam_role.lambda_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.lambda_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "aws_ec2_readonly" {
    role       = aws_iam_role.lambda_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy" "custom_policy" {
    name = "serverless-cost-optimizer-inline-permissions"
    role = aws_iam_role.lambda_execution_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "sns:Publish",
                    "ce:GetCostAndUsage"
                ]
                Effect   = "Allow"
                Resource = "*"
            },
        ]
    })
}

