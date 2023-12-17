variable "profile" {
  default = "default"
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "root_lambda_name" {
  default = "root_lambda"
}

variable "root_image_uri" {

}

variable "root_lambda_memory_size" {
  # per https://docs.aws.amazon.com/lambda/latest/dg/configuration-memory.html
  default = 1769
}

variable "root_lambda_timeout" {
  default = 900
}

variable "root_docker_image_repository_url" {
  default = "public.ecr.aws/u1r6s2k6/root_lambda"
}

variable "lambda_role_arn" {
  default = ""
}
