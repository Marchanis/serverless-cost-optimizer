data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"

}

resource "aws_lambda_function" "lambda_function" {
    function_name = "serverless-cost-optimizer"
    role    = aws_iam_role.lambda_execution_role.arn
    handler = "lambda_function.lambda_handler"
    runtime = "python3.11"
    filename = data.archive_file.lambda_zip.output_path
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    timeout = 30

    environment {
        variables = {
            SNS_TOPIC_ARN = aws_sns_topic.sns_topic.arn
        }
    }
}