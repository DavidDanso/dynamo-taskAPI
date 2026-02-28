# Zip the Python file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.lambda}/handler.py"
  output_path = "${path.lambda}/handler.zip"
}