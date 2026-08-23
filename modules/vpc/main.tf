terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# Intentionally no resources here. This module re-exposes the VPC created and
# owned by homelab-infrastructure (see envs/dev/remote_state.tf) as a
# consistent module interface, so other modules/callers in this repo depend on
# module.vpc.* rather than reaching into the remote state data source
# directly. Nothing in this POC actually places resources into the VPC yet -
# this exists so a later feature that does (e.g. an API Gateway VPC link)
# has somewhere to extend without restructuring callers.
