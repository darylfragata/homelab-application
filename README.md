# homelab-application

Application-layer AWS resources (Lambda, IAM, SSM Parameter Store) for the homelab, as opposed to `homelab-infrastructure`'s networking/compute/CI-agent layer. See `homelab-documentation`'s `ARCHITECTURE.md`/`ROADMAP.md` for the wider picture.

## Current POC

`envs/dev` provisions two Lambda functions from `local.lambda_functions` (`envs/dev/locals.tf`):

- `pc_demo` - has its own dedicated SSM parameter (`ssm_parameter = true`) and scheduled Provisioned Concurrency (`provisioned_concurrency = true`).
- `pc_monitor` - neither right now; its original purpose (Provisioned Concurrency monitoring) is on hold, and `src/pc_monitor/handler.py` is stale until that's revisited.

Module layout: `modules/vpc` (thin re-export of the existing dev VPC from `homelab-infrastructure`, unused by this POC but kept for future use), `modules/lambda_backend` (execution role + optional extra IAM policy + optional dedicated SSM parameter + optional Provisioned Concurrency, static or scheduled + the function itself - "one stack" per function), `modules/ssm_parameter` (thin generic `aws_ssm_parameter` wrapper, currently unused - kept for future use, same as `modules/vpc`).

### Provisioned Concurrency (provisioned_concurrency.tf)

Any `lambda_functions` entry can set `provisioned_concurrency = true`; `main.tf` then looks up that function's actual config (base capacity, plus an optional list of scheduled scaling actions) from `envs/dev/provisioned_concurrency.tf`'s `local.provisioned_concurrency_config`, keyed by function name - a `true` entry with no matching config there fails the plan rather than silently doing nothing.

- **Static only** (empty `scheduled_actions`): `modules/lambda_backend` publishes a version, creates a `live` alias, and a plain `aws_lambda_provisioned_concurrency_config` pinned to `base_capacity`.
- **Scheduled**: each entry in `scheduled_actions` is `{name, schedule, capacity}` - `schedule` is an AWS schedule expression (e.g. `"cron(0 8 ? * MON-FRI *)"`). This registers an `aws_appautoscaling_target` for the function's PC and one `aws_appautoscaling_scheduled_action` per entry, pinning capacity to that value from the scheduled time until the next one fires. Once a schedule exists, Application Auto Scaling - not Terraform - owns the live capacity number, so the PC config resource has `lifecycle { ignore_changes = [provisioned_concurrent_executions] }` to avoid fighting it on every apply; `pc_demo`'s current example scales to 3 at 8am and back to 1 at 6pm, Mon-Fri.

### Per-function SSM parameter (ssm_template/)

Any `lambda_functions` entry can set `ssm_parameter = true` to get its own dedicated SSM parameter (`/<project_name>/<environment>/lambda/<function_name>/config`), with `ssm:GetParameter` on that one parameter automatically granted to its execution role (no need to list it in `permission`) and its name injected as the `OWN_SSM_PARAMETER_NAME` environment variable.

Its **value** comes from a template file at `ssm_template/<function_name>.json` (repo root - see `ssm_template/pc_demo.json` for the working example), read as-is with no interpolation. If no such file exists for a function with `ssm_parameter = true`, the parameter is still created, just with a placeholder value (`"No template found for this function - add ssm_template/<function_name>.json and re-apply."`) instead of failing the plan.

### Source code / deployment package (S3)

Terraform does **not** package or upload function code - `modules/lambda_backend` no longer has an `archive_file`/`filename` step at all (that, and the `hashicorp/archive` provider, were removed). Each function's `aws_lambda_function` just references an existing S3 object:

```
s3://df-iac-artifacts/<environment>/<function_name>.zip
```

e.g. `s3://df-iac-artifacts/dev/pc_demo.zip`. Uploading that zip (from `src/<function_name>/`, still the source of truth for what to build) is on you - manually or via a future CI step, not this repo's Terraform. One consequence worth knowing: since nothing in the `aws_lambda_function` resource tracks the object's content (no `source_code_hash`/`s3_object_version`), re-running `terraform apply` after you upload a new zip to the same key will **not** redeploy it - Terraform sees no attribute change. Trigger that separately, e.g. `aws lambda update-function-code --function-name pc_demo --s3-bucket df-iac-artifacts --s3-key dev/pc_demo.zip`.

### Configuration (tfvars)

tfvars only holds the values that genuinely vary per apply - `environment` and `project_name`. Not committed (`.gitignore` excludes `*.tfvars`), lives locally alongside `homelab-infrastructure`'s own tfvars mirror:

```
D:\OneDrive\github\tfvars\dev-app.tfvars
```

(same folder as that repo's `dev-infra.tfvars`/`prod-infra.tfvars`/`shared-infra.tfvars`, just `-app` instead of `-infra` for this repo; not uploaded to S3, local only).

```bash
terraform plan -var-file=D:\OneDrive\github\tfvars\dev-app.tfvars
```

The Lambda backends themselves (`lambda_functions` - what functions exist, their permissions) are **not** tfvars input - they're the actual thing this repo provisions, not a per-apply value, so they're committed directly in `envs/dev/locals.tf`.

### IAM permissions (policy.tf)

Named, reusable IAM policies live in `envs/dev/policy.tf` as `data "aws_iam_policy_document"` blocks (real IAM JSON, not a custom schema), collected into a `name -> JSON` lookup map (`local.policy_documents`) - currently empty. Each `lambda_functions` entry opts into any of them by name via its `permission` list - `main.tf` looks those names up and hands the resulting JSON documents to `module.lambda_backend`, which merges them into that function's single inline role policy alongside its own-SSM-parameter grant (if `ssm_parameter = true`). A policy shared by multiple functions is defined once in `policy.tf` and just listed wherever it's needed.

### Cross-repo dependency

`envs/dev/remote_state.tf` reads `homelab-infrastructure`'s dev state (`vpc_id`, `private_subnet_ids`) read-only. No IAM change is needed in `homelab-infrastructure`'s `ado_agent` role to run this repo's Terraform - its existing policy (`modules/ado_agent/main.tf`'s `aws_iam_policy.this`) already grants broad access, including `ssm:*` on `Resource: "*"`.

### Verify after apply

```bash
aws ssm get-parameter --name "/df-homelab/dev/lambda/pc_demo/config" --query Parameter.Value --output text
aws lambda get-provisioned-concurrency-config --function-name pc_demo --qualifier live
aws application-autoscaling describe-scheduled-actions --service-namespace lambda --resource-id function:pc_demo:live
```

### Out of scope for this POC

API Gateway, `envs/prod`, a CI/CD pipeline for this repo, PC utilization monitoring (`pc_monitor` is stale pending a redesign), and PC over/under-provisioning analysis.
