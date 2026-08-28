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
    pc_demo = {
      description = "Demo function with its own SSM config parameter."
      handler     = "handler.handler"
      runtime     = "python3.13"
      memory_size = 128
      timeout     = 10
      environment_variables = {
        LOG_LEVEL = "INFO"
        GREETING  = "hello from pc_demo"
      }
      permission    = ["cloudwatch_put_metrics"]
      ssm_parameter = true
    }
    pc_monitor = {
      description           = "Placeholder function - monitoring logic not yet implemented."
      handler               = "handler.handler"
      runtime               = "python3.13"
      memory_size           = 128
      timeout               = 10
      environment_variables = {}
      permission            = []
      ssm_parameter         = false
    }
  }

  portfolio_site = {
    # Account ID suffix guarantees S3's global bucket-name uniqueness without
    # a tfvars entry. Deliberately distinct from homelab-infrastructure's
    # decommissioned static_site bucket name (extra "-site-" segment) so this
    # bucket's creation has no ordering dependency on that bucket's destroy.
    bucket_name = "${var.project_name}-portfolio-site-${var.environment}-${data.aws_caller_identity.current.account_id}"
  }
}
