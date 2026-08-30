# homelab-application

Application-layer AWS resources (Lambda, IAM, SSM Parameter Store) for the homelab. This is the counterpart to the sibling repo `homelab-infrastructure`, which owns networking/compute/CI-agent layer; this repo consumes that repo's remote state via `envs/dev/remote_state.tf`.

## Structure

- `envs/dev/` — root module: `main.tf`, `variables.tf`, `locals.tf`, `outputs.tf`, `provider.tf` (Terraform `>= 1.7.0`), `backend.tf`, `remote_state.tf` (reads `homelab-infrastructure` state), `policy.tf` (named IAM policy docs). Owns `dev.darylfragata.com`'s portfolio bucket plus the (currently empty) Lambda POC scaffolding.
- `envs/prod/` — lean root module, `portfolio_site` only (no VPC/Lambda): `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`, `backend.tf`. Owns `darylfragata.com`'s portfolio bucket — reassigned here from `envs/dev` via `terraform state rm`/`import`, not recreated.
- `templates/` — shared pipeline step templates (`terraform-plan-steps.yml`, `terraform-apply-steps.yml`), same shape as `homelab-infrastructure`'s. No `tfvars-sync.yml` here — `homelab-infrastructure`'s tfvars sync now covers this repo too (see CI/CD below).
- `modules/lambda_backend/` — per-function Lambda: IAM role/assume-role policy, `AWSLambdaBasicExecutionRole` attachment, optional dedicated SSM config parameter (sourced from `ssm_template/<function_name>.json`, falls back to a placeholder if missing), extra attachable policy documents.
- `modules/ssm_parameter/` — thin generic SSM Parameter Store resource wrapper.
- `modules/vpc/` — intentionally empty passthrough (no resources); re-exposes `homelab-infrastructure`'s remote-state VPC/subnet IDs as `module.vpc.*` so callers don't reach into the remote-state data source directly. Scaffolding for a future feature (e.g. API Gateway VPC link).
- `modules/portfolio_site/` — public-read S3 bucket with static website hosting for the portfolio site (site source lives in the sibling `homelab-portfolio` repo; that repo's own pipeline syncs content directly to S3 — no Terraform-managed content object). Sits behind Cloudflare (proxied CNAME, SSL/TLS mode Flexible — see `homelab-documentation`'s ADR-008 and its Cloudflare runbook). Replaces an earlier CloudFront-fronted version of this same site that lived in `homelab-infrastructure` (decommissioned).
- `src/pc_demo/`, `src/pc_monitor/` — Lambda handler Python source + prebuilt `.zip` artifacts for the two POC functions.
- `ssm_template/` — per-function SSM config templates (e.g. `pc_demo.json`).
- `pipelines/azure-pipelines-deploy.yml` — CI/CD pipeline (Azure DevOps — there is no `.github/workflows/` in this repo).
- `templates/env-deploy.yml` — reusable stage-level template (Plan stage + Apply deployment-job stage) parameterized by environment; `terraform-plan-steps.yml`/`terraform-apply-steps.yml` remain the step-level templates it wraps.
- `docs/terraform-checks.md` — tool reference doc explaining why each Validate check exists and how to change it.
- `.tflint.hcl`, `.checkov.yaml` — linter/scanner config.

## CI/CD

One Azure Pipeline, `pipelines/azure-pipelines-deploy.yml`, on the self-hosted `AWS-Agents` pool, triggered on push to `develop`:

- **Validate** stage — pinned `terraform fmt -check -recursive` / `init -backend=false` / `validate` in both `envs/dev` and `envs/prod` → pinned TFLint 0.53.0 (`--recursive --minimum-failure-severity=error`) → pinned Checkov 3.2.257: advisory full scan (non-blocking) then a blocking gate on `CKV_AWS_40,1,62,63,355` (IAM/wildcard/public-bucket checks) → publishes a `terraform-checks-summary` artifact. Never runs `apply`; a failure here stops the pipeline before Dev is even planned.
- **Dev** (`templates/env-deploy.yml`, `dependsOn: Validate`) then **Prod** (`dependsOn: DevApply`) — sequential: Prod's Plan stage doesn't start until Dev's Apply has succeeded. Within each environment, Plan runs automatically and publishes a `tfplan-<env>` artifact; Apply is a `deployment` job bound to the `dev-app-deployment`/`prod-app-deployment` ADO Environment, gated by a manual approval configured there, and applies that same downloaded plan artifact rather than re-planning.

Tfvars (`dev-app.tfvars`/`prod-app.tfvars`) aren't synced by anything in this repo — `homelab-infrastructure`'s `tfvars-sync-pipeline.yml` does an `aws s3 sync` of the *entire* `df-iac-tfvars` bucket onto the agent, which covers this repo's tfvars too as long as they're uploaded under their environment's folder (`s3://df-iac-tfvars/dev/dev-app.tfvars`, `.../prod/prod-app.tfvars` — see `homelab-prereqs/03-upload-tfvars.sh`), landing locally at `/home/ubuntu/tfvars/dev/dev-app.tfvars` / `.../prod/prod-app.tfvars` — the exact path `templates/terraform-plan-steps.yml` reads.

Same overall shape as `homelab-infrastructure`'s pipeline (ADR-005 in `homelab-documentation`) — see `docs/terraform-checks.md`'s mermaid diagram for how Validate and the per-env stages fit together.

For the reasoning behind specific lint/scan rule choices, read `docs/terraform-checks.md` rather than duplicating it here.
