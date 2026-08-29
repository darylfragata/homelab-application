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

variable "s3_bucket_name" {
  description = "S3 bucket name for the portfolio site. Must be globally unique."
  type        = string
}
