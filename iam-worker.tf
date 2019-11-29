resource "aws_iam_instance_profile" "worker_profile" {
  name = "FibLambdaJenkinsWorkerProfile"
  role = aws_iam_role.worker_role.name
}

resource "aws_iam_role" "worker_role" {
  name = "FibLambdaJenkinsBuildRole"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "s3_policy" {
  name = "FibLambdaPushToS3Policy"
  path = "/"

  policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.bucket.arn}/*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name = "FibLambdaDeployLambdaPolicy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "lambda:UpdateFunctionCode",
        "lambda:PublishVersion",
        "lambda:UpdateAlias"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "worker_s3_attachment" {
  role = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "worker_lambda_attachment" {
  role = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
