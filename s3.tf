resource "aws_s3_bucket" "bucket" {
  bucket = "fib-lambda-s3-bucket"
  acl = "private"
}