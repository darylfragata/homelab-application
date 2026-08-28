output "bucket_name" {
  description = "Name of the S3 bucket holding the site content."
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket holding the site content."
  value       = aws_s3_bucket.site.arn
}

output "website_endpoint" {
  description = "S3 static website hosting endpoint (plain HTTP) - browse this to verify the site, and the origin to later point Cloudflare at."
  value       = aws_s3_bucket_website_configuration.site.website_endpoint
}

output "website_domain" {
  description = "S3 static website hosting domain, without the http:// scheme."
  value       = aws_s3_bucket_website_configuration.site.website_domain
}
