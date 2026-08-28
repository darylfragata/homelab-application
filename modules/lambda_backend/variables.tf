variable "function_name" {
  description = "Lambda function name. Also used to build the execution role's name."
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

variable "description" {
  description = "Description of what the function does."
  type        = string
}

variable "artifact_bucket" {
  description = "S3 bucket holding this function's deployment package. Uploaded externally (not by this Terraform) to <environment>/<function_name>.zip - Terraform only references that key, it doesn't manage the object. Re-running `terraform apply` after a new zip is uploaded to the same key does NOT redeploy it (nothing in this resource's tracked attributes changes) - trigger a redeploy separately (e.g. `aws lambda update-function-code`)."
  type        = string
}

variable "handler" {
  description = "Function entrypoint, e.g. handler.handler."
  type        = string
}

variable "runtime" {
  description = "Lambda runtime identifier, e.g. python3.13."
  type        = string
}

variable "memory_size" {
  description = "Memory allocated to the function, in MB."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Function timeout, in seconds."
  type        = number
  default     = 10
}

variable "environment_variables" {
  description = "Environment variables passed to the function."
  type        = map(string)
  default     = {}
}

variable "extra_policy_documents" {
  description = "Additional IAM policy documents (rendered JSON, e.g. from named data \"aws_iam_policy_document\" blocks) attached to this function's execution role, beyond the basic Lambda execution managed policy. Merged into a single inline role policy via the aws provider's built-in document-merge mechanism. Leave empty for functions that only need basic execution logging."
  type        = list(string)
  default     = []
}

variable "ssm_parameter" {
  description = "Whether to create a dedicated SSM parameter for this function. When true, an aws_ssm_parameter is created at /<project_name>/<environment>/lambda/<function_name>/config, this function's role automatically gets ssm:GetParameter scoped to it (no need to list it in `permission`), and its name is injected into the function as the OWN_SSM_PARAMETER_NAME environment variable."
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention period, in days, for this function's log group."
  type        = number
  default     = 14
}
