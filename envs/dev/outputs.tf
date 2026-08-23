output "lambda_function_arns" {
  description = "ARNs of all Lambda functions created in this environment, keyed by function name."
  value       = { for name, mod in module.lambda_backend : name => mod.function_arn }
}

output "lambda_ssm_parameter_names" {
  description = "Names of each function's dedicated SSM parameter, keyed by function name. Null for functions with ssm_parameter = false."
  value       = { for name, mod in module.lambda_backend : name => mod.ssm_parameter_name }
}

output "lambda_pc_alias_arns" {
  description = "ARNs of each function's Provisioned Concurrency alias, keyed by function name. Null for functions without PC enabled."
  value       = { for name, mod in module.lambda_backend : name => mod.alias_arn }
}
