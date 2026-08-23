variable "name" {
  description = "SSM Parameter Store parameter name (including leading slash for a hierarchical name)."
  type        = string
}

variable "description" {
  description = "Description of what this parameter holds and how its value is produced."
  type        = string
}

variable "type" {
  description = "SSM parameter type."
  type        = string
  default     = "String"

  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.type)
    error_message = "Type must be String, StringList, or SecureString."
  }
}

variable "value" {
  description = "Parameter value."
  type        = string
}

variable "tier" {
  description = "SSM parameter tier."
  type        = string
  default     = "Standard"
}
