output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.frontend.arn
}

output "bucket_regional_domain_name" {
  description = "Domain name regional del bucket"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "cloudfront_id" {
  description = "ID de la distribución CloudFront"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_arn" {
  description = "ARN de la distribución CloudFront"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "cloudfront_domain" {
  description = "Dominio de CloudFront (sin https://)"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_url" {
  description = "URL completa de CloudFront"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted Zone ID de CloudFront para Route53"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}