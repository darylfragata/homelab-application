output "function_name" {
  description = "Lambda function name."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda function ARN."
  value       = aws_lambda_function.this.arn
}

output "role_name" {
  description = "Name of the Lambda execution role."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.this.arn
}

output "ssm_parameter_arn" {
  description = "ARN of this function's dedicated SSM parameter, or null when var.ssm_parameter is false."
  value       = var.ssm_parameter ? aws_ssm_parameter.this[0].arn : null
}

output "ssm_parameter_name" {
  description = "Name of this function's dedicated SSM parameter, or null when var.ssm_parameter is false."
  value       = var.ssm_parameter ? aws_ssm_parameter.this[0].name : null
}

output "log_group_name" {
  description = "Name of this function's CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of this function's CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.arn
}

output "alias_arn" {
  description = "ARN of the alias fronting the Provisioned Concurrency version, or null when PC is not enabled."
  value       = var.provisioned_concurrent_executions != null ? aws_lambda_alias.this[0].arn : null
}

output "scheduled_action_names" {
  description = "Names of the Application Auto Scaling scheduled actions created for this function's PC, if any."
  value       = [for action in aws_appautoscaling_scheduled_action.this : action.name]
}
