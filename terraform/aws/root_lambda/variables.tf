
variable "handler" {
  default = "lambda.lambda_handler"
}

variable "memory_size" {}

variable "timeout" {
  default = 900
}

variable "run" {
  default = false
}

variable "lambda_name" {
  default = "root_lambda"
}

variable "lambda_role_arn" {
  default = ""
}

variable "root_image_uri" {}

variable "aws_region" {}

variable "processing_bucket" {}
