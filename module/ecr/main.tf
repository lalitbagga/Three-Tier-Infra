resource "aws_ecr_repository" "app" {
  name                 = "three-tier-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "three-tier-app"
  }
}