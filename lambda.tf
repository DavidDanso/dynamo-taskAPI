# Lambda function resource
resource "aws_lambda_function" "tasks_function" {
  function_name    = var.lambda_function_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  handler          = "lambda_function.handler"
  role             = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.tasks.name
    }
  }

  tags = {
    Name        = var.lambda_function_name
    Environment = var.stage_name
  }
}