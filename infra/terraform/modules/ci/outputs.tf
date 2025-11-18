output "artifacts_bucket_name" {
  description = "Name of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the artifacts S3 bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "ci_role_arn" {
  description = "ARN of the CI IAM role"
  value       = aws_iam_role.ci_role.arn
}
