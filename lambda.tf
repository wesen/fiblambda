resource "aws_lambda_function" "function" {
  filename      = "deployment.zip"
  function_name = "Fibonacci"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main"
  runtime       = "go1.x"
}