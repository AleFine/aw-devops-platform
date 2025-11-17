resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than ${var.expire_untagged_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.expire_untagged_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 99 # 'any' must be evaluated last
        description  = "Keep only the last ${var.retain_last} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.retain_last
        }
        action = { type = "expire" }
      }
    ]
  })
}
