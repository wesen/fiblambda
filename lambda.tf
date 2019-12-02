resource "aws_lambda_function" "function" {
  filename      = "deployment.zip"
  function_name = "Fibonacci"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main"
  runtime       = "go1.x"
}

resource "aws_lambda_alias" "function_alias" {
  function_name = aws_lambda_function.function.function_name
  function_version = 2
  name = "production"
}