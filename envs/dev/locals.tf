data "aws_caller_identity" "current" {}

locals {
  # Lambda backends for this POC. Not a variable/tfvars input - these are the
  # actual functions this repo provisions, not a per-apply/per-environment
  # value, so they're committed here directly.
  #
  # `permission` is a list of named policies from policy.tf's
  # local.policy_documents to attach to that function's role.
  #
  # `ssm_parameter = true` gives the function its own dedicated SSM parameter
  # and read access to it (see modules/lambda_backend). Its value comes from
  # ssm_template/<function_name>.json if present.
  #
  # Source code lives in src/<function_name>/ for reference, but Terraform no
  # longer packages/uploads it - each function's deployment package is
  # uploaded externally to s3://<var.artifact_bucket_name>/<environment>/<function_name>.zip
  # (see modules/lambda_backend), and this map only references that key.
  lambda_functions = {

  }

}
