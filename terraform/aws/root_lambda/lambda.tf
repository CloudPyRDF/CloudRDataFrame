resource "aws_lambda_function" "worker_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.root_repository.repository_url}:worker"
  function_name = "worker_${var.lambda_name}"
  role          = var.lambda_role_arn == "" ? aws_iam_role.lambda_role[0].arn : var.lambda_role_arn
  memory_size   = var.memory_size
  timeout       = var.timeout

  environment {
    variables = {
      bucket = var.processing_bucket.bucket
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

  depends_on = [aws_ecr_repository.root_repository]
}

resource "aws_lambda_function" "replicator_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.root_repository.repository_url}:replicator"
  function_name = "replicator_${var.lambda_name}"
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

  depends_on = [aws_ecr_repository.root_repository]
}

resource "aws_lambda_function" "reducer_lambda" {
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.root_repository.repository_url}:reducer"
  function_name = "reducer_${var.lambda_name}"
  role          = var.lambda_role_arn == "" ? aws_iam_role.lambda_role[0].arn : var.lambda_role_arn
  memory_size   = var.memory_size
  timeout       = var.timeout

  environment {
    variables = {
      bucket = var.processing_bucket.bucket
    }
  }

  image_config {
    entry_point = [
      "bash", "-c",
      "python3 -m awslambdaric lambda.lambda_handler"
    ]
    working_directory = "/opt"
  }

  depends_on = [aws_ecr_repository.root_repository]
}

resource "aws_lambda_function" "kickoff_lambda" {
  function_name    = "kickoff_${var.lambda_name}"
  handler          = "kickoff.lambda_handler"
  runtime          = "python3.10"
  filename         = "generated/kickoff.zip"
  source_code_hash = filebase64("generated/kickoff.zip")

  role = var.lambda_role_arn == "" ? aws_iam_role.lambda_role[0].arn : var.lambda_role_arn

  timeout = var.timeout
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.processing_bucket.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.reducer_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "output/"
    filter_suffix       = ".out"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reducer_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.processing_bucket.bucket}"
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
