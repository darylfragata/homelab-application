output "portfolio_site_bucket_name" {
  description = "Name of the S3 bucket holding the portfolio site content."
  value       = module.portfolio_site.bucket_name
}

output "portfolio_site_website_endpoint" {
  description = "S3 static website hosting endpoint (plain HTTP) - browse this to verify the site, and the origin Cloudflare is pointed at."
  value       = module.portfolio_site.website_endpoint
}
