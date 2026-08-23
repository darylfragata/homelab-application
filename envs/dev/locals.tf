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
  # `provisioned_concurrency = true` provisions PC using the matching entry
  # in provisioned_concurrency.tf's local.provisioned_concurrency_config
  # (base capacity, plus optional scheduled scaling).
  #
  # Source code lives in src/<function_name>/ for reference, but Terraform no
  # longer packages/uploads it - each function's deployment package is
  # uploaded externally to s3://<var.artifact_bucket_name>/<environment>/<function_name>.zip
  # (see modules/lambda_backend), and this map only references that key.
  lambda_functions = {
    pc_demo = {
      description = "Demo function with its own SSM config parameter. Provisioned Concurrency disabled - the AWS account's total Lambda concurrency limit is 10 (the hard minimum), leaving zero headroom for PC. Revisit once/if that quota is raised."
      handler     = "handler.handler"
      runtime     = "python3.13"
      memory_size = 128
      timeout     = 10
      environment_variables = {
        LOG_LEVEL = "INFO"
        GREETING  = "hello from pc_demo"
      }
      permission              = ["cloudwatch_put_metrics"]
      ssm_parameter           = true
      provisioned_concurrency = false
    }
    pc_monitor = {
      description             = "Reads the PC-monitored function list from SSM and checks utilization."
      handler                 = "handler.handler"
      runtime                 = "python3.13"
      memory_size             = 128
      timeout                 = 10
      environment_variables   = {}
      permission              = []
      ssm_parameter           = false
      provisioned_concurrency = false
    }
  }
}
