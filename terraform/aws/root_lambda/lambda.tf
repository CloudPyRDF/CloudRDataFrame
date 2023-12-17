resource "aws_lambda_function" "lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.root_worker.repository_url}:latest"
  function_name = var.lambda_name
  role          = var.lambda_role_arn == "" ? aws_iam_role.lambda_role[0].arn : var.lambda_role_arn
  memory_size   = var.memory_size
  timeout       = var.timeout

  environment {
    variables = {
      bucket     = var.processing_bucket.bucket
      KRB5CCNAME = "/tmp/certs"
      XRD_NETWORKSTACK = "IPv4"
    }
  }

  image_config {
    entry_point = [
      "bash", "-c",
      "python3 -m awslambdaric lambda.lambda_handler"
    ]
    working_directory = "/opt"
  }

  depends_on = [aws_ecr_repository.root_worker]
}

resource "aws_iam_role" "lambda_role" {
  count = var.lambda_role_arn == "" ? 1 : 0
  name = "${var.lambda_name}_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_policy" "lambda_policy" {
  count = var.lambda_role_arn == "" ? 1 : 0
  name   = "${var.lambda_name}_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": "*",
        "Resource": "*",
        "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  count = var.lambda_role_arn == "" ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.lambda_policy[0].arn
}
