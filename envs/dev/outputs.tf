output "lambda_function_arns" {
  description = "ARNs of all Lambda functions created in this environment, keyed by function name."
  value       = { for name, mod in module.lambda_backend : name => mod.function_arn }
}

output "lambda_ssm_parameter_names" {
  description = "Names of each function's dedicated SSM parameter, keyed by function name. Null for functions with ssm_parameter = false."
  value       = { for name, mod in module.lambda_backend : name => mod.ssm_parameter_name }
}

output "portfolio_site_bucket_name" {
  description = "Name of the S3 bucket holding the portfolio site content."
  value       = module.portfolio_site.bucket_name
}

output "portfolio_site_website_endpoint" {
  description = "S3 static website hosting endpoint (plain HTTP) - browse this to verify the site, and the origin to later point Cloudflare at."
  value       = module.portfolio_site.website_endpoint
}
