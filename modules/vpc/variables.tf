variable "vpc_id" {
  description = "ID of the existing VPC (created in homelab-infrastructure) to re-expose."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs of the existing VPC (created in homelab-infrastructure) to re-expose."
  type        = list(string)
}
