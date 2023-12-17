resource "aws_ecr_repository" "root_worker" {
  name                 = "root_worker"
  image_tag_mutability = "MUTABLE"

  provisioner "local-exec" {
    command = "./push_image.sh ${self.name}:latest ${var.root_image_uri} ${var.aws_region}"
  }

  tags = {
    "app:region" = var.aws_region
  }

  provisioner "local-exec" {
    when    = destroy
    command = "./destroy_ecr.sh ${self.name} ${self.tags["app:region"]}"
  }
}
