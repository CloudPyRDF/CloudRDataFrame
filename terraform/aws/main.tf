module "root" {
  source         = "./root_lambda"
  lambda_name    = var.root_lambda_name
  memory_size    = var.root_lambda_memory_size
  timeout        = var.root_lambda_timeout
  root_image_uri = var.root_image_uri
  aws_region     = var.aws_region
  lambda_role_arn    = var.lambda_role_arn
  processing_bucket  = aws_s3_bucket.processing_bucket
}
