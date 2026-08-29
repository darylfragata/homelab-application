module "portfolio_site" {
  source = "../../modules/portfolio_site"

  bucket_name  = var.s3_bucket_name
  environment  = var.environment
  project_name = var.project_name
}
