terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.environment}-${var.project_name}-${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# This function's own dedicated config parameter - only created when
# var.ssm_parameter is true. Read access to it is granted automatically
# below, not via the `permission` list, since it's a structural consequence
# of enabling this rather than something to name/opt into separately.
#
# Value comes from a template file at ssm_template/<function_name>.json (repo
# root, sibling to envs/ and modules/), read as-is with no interpolation. If
# no such file exists, the parameter is still created with a placeholder
# value that says so, rather than failing - add the template file and
# re-apply to pick it up.
locals {
  ssm_template_path  = "${path.root}/../../ssm_template/${var.function_name}.json"
  ssm_template_value = fileexists(local.ssm_template_path) ? file(local.ssm_template_path) : "No template found for this function - add ssm_template/${var.function_name}.json and re-apply."
}

resource "aws_ssm_parameter" "this" {
  count = var.ssm_parameter ? 1 : 0

  name        = "/${var.project_name}/${var.environment}/lambda/${var.function_name}/config"
  description = "Dedicated config parameter for the ${var.function_name} Lambda function."
  type        = "String"
  value       = local.ssm_template_value
}

data "aws_iam_policy_document" "own_ssm_parameter_read" {
  count = var.ssm_parameter ? 1 : 0

  statement {
    sid       = "ReadOwnSsmParameter"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.this[0].arn]
  }
}

data "aws_iam_policy_document" "extra" {
  count = length(var.extra_policy_documents) > 0 || var.ssm_parameter ? 1 : 0

  source_policy_documents = concat(
    var.extra_policy_documents,
    var.ssm_parameter ? [data.aws_iam_policy_document.own_ssm_parameter_read[0].json] : []
  )
}

resource "aws_iam_role_policy" "extra" {
  count = length(var.extra_policy_documents) > 0 || var.ssm_parameter ? 1 : 0

  name   = "${var.function_name}-extra"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.extra[0].json
}

locals {
  # Deployment package lives in S3, uploaded externally - see var.artifact_bucket.
  artifact_key = "${var.environment}/${var.function_name}.zip"

  environment_variables = var.ssm_parameter ? merge(var.environment_variables, {
    OWN_SSM_PARAMETER_NAME = aws_ssm_parameter.this[0].name
  }) : var.environment_variables
}

# Named to match Lambda's own auto-created log group exactly, so this is
# adopted rather than duplicated - without it, AWS creates the same-named
# group itself on first invocation with no retention policy (kept forever)
# and outside Terraform's state.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.this.arn
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout
  s3_bucket     = var.artifact_bucket
  s3_key        = local.artifact_key
  # A version must be published for provisioned_concurrent_executions - PC
  # configs attach to a specific version (via an alias), never to $LATEST.
  publish = var.provisioned_concurrent_executions != null

  dynamic "environment" {
    for_each = length(local.environment_variables) > 0 ? [local.environment_variables] : []

    content {
      variables = environment.value
    }
  }

  # Ensures our log group (with its retention policy) exists before the
  # function can be invoked, instead of racing AWS's own auto-create.
  depends_on = [aws_cloudwatch_log_group.this]
}

# Provisioned Concurrency is part of this same function's stack, not a
# separate concern - only created when requested via
# var.provisioned_concurrent_executions.
resource "aws_lambda_alias" "this" {
  count = var.provisioned_concurrent_executions != null ? 1 : 0

  name             = var.alias_name
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}

# Static baseline PC config, used as-is whenever there's no schedule to
# override it later.
resource "aws_lambda_provisioned_concurrency_config" "static" {
  count = var.provisioned_concurrent_executions != null && length(var.scheduled_actions) == 0 ? 1 : 0

  function_name                     = aws_lambda_function.this.function_name
  qualifier                         = aws_lambda_alias.this[0].name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
}

# Same resource, but for the scheduled case: once Application Auto Scaling
# below is registered as the scalable target, it becomes the source of truth
# for the live capacity after each scheduled action fires. Without
# ignore_changes here, Terraform would try to reset the count back to the
# static baseline on every apply, fighting whichever schedule last fired.
resource "aws_lambda_provisioned_concurrency_config" "scheduled" {
  count = var.provisioned_concurrent_executions != null && length(var.scheduled_actions) > 0 ? 1 : 0

  function_name                     = aws_lambda_function.this.function_name
  qualifier                         = aws_lambda_alias.this[0].name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions

  lifecycle {
    ignore_changes = [provisioned_concurrent_executions]
  }
}

resource "aws_appautoscaling_target" "this" {
  count = length(var.scheduled_actions) > 0 ? 1 : 0

  service_namespace  = "lambda"
  resource_id        = "function:${aws_lambda_function.this.function_name}:${aws_lambda_alias.this[0].name}"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  min_capacity       = var.provisioned_concurrent_executions
  max_capacity       = var.provisioned_concurrent_executions

  depends_on = [aws_lambda_provisioned_concurrency_config.scheduled]
}

resource "aws_appautoscaling_scheduled_action" "this" {
  for_each = { for action in var.scheduled_actions : action.name => action }

  name               = "${var.function_name}-${each.key}"
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  schedule           = each.value.schedule

  scalable_target_action {
    min_capacity = each.value.capacity
    max_capacity = each.value.capacity
  }
}
