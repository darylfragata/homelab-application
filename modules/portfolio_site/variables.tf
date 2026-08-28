variable "bucket_name" {
  description = "Globally-unique S3 bucket name for the site content."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Project name used for resource names and tags."
  type        = string
}

variable "index_document" {
  description = "S3 key served as the website's index document."
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "S3 key served as the website's error document."
  type        = string
  default     = "error.html"
}
