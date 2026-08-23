variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Project name used for resource names and tags. Should match the value used for homelab-infrastructure so default_tags stay consistent across repos."
  type        = string
}

variable "aws_region" {
  description = "AWS region for regional resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "artifact_bucket_name" {
  description = "S3 bucket holding Lambda deployment packages, uploaded externally (not by this Terraform) to <environment>/<function_name>.zip - see modules/lambda_backend."
  type        = string
  default     = "df-iac-artifacts"
}
