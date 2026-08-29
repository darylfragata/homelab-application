module "vpc" {
  source = "../../modules/vpc"

  vpc_id             = data.terraform_remote_state.infra.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.infra.outputs.private_subnet_ids
}

module "lambda_backend" {
  source   = "../../modules/lambda_backend"
  for_each = local.lambda_functions

  function_name         = each.key
  environment           = var.environment
  project_name          = var.project_name
  description           = each.value.description
  handler               = each.value.handler
  runtime               = each.value.runtime
  memory_size           = each.value.memory_size
  timeout               = each.value.timeout
  environment_variables = each.value.environment_variables
  ssm_parameter         = each.value.ssm_parameter
  artifact_bucket       = var.artifact_bucket_name

  # Named policies from policy.tf's local.policy_documents, looked up by name
  # from this function's `permission` list (envs/dev/locals.tf).
  extra_policy_documents = [
    for name in each.value.permission : local.policy_documents[name]
  ]
}

module "portfolio_site" {
  source = "../../modules/portfolio_site"

  bucket_name  = var.s3_bucket_name
  environment  = var.environment
  project_name = var.project_name
}
