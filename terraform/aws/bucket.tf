resource "aws_s3_bucket" "processing_bucket" {
  acl           = "private"
  force_destroy = true

  tags = {
    Name        = "ROOT Processing Bucket"
    Environment = "Dev"
  }
}
