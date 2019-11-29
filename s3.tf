resource "aws_s3_bucket" "bucket" {
  bucket = "FibLambdaS3Bucket"
  acl = "private"
}