# homelab-application

Application-layer AWS resources (Lambda, IAM, SSM Parameter Store) for the homelab. This is the counterpart to the sibling repo `homelab-infrastructure`, which owns networking/compute/CI-agent layer; this repo consumes that repo's remote state via `envs/dev/remote_state.tf`.

## Structure

- `envs/dev/` — the one live root module: `main.tf`, `variables.tf`, `locals.tf`, `outputs.tf`, `provider.tf` (Terraform `>= 1.7.0`), `backend.tf`, `remote_state.tf` (reads `homelab-infrastructure` state), `policy.tf` (named IAM policy docs).
- `modules/lambda_backend/` — per-function Lambda: IAM role/assume-role policy, `AWSLambdaBasicExecutionRole` attachment, optional dedicated SSM config parameter (sourced from `ssm_template/<function_name>.json`, falls back to a placeholder if missing), extra attachable policy documents.
- `modules/ssm_parameter/` — thin generic SSM Parameter Store resource wrapper.
- `modules/vpc/` — intentionally empty passthrough (no resources); re-exposes `homelab-infrastructure`'s remote-state VPC/subnet IDs as `module.vpc.*` so callers don't reach into the remote-state data source directly. Scaffolding for a future feature (e.g. API Gateway VPC link).
- `modules/portfolio_site/` — public-read S3 bucket with static website hosting for the portfolio site (site source lives in the sibling `homelab-portfolio` repo, uploaded manually — no Terraform-managed content object, no CI/CD deploy pipeline yet). Meant to sit behind Cloudflare later; replaces an earlier CloudFront-fronted version of this same site that lived in `homelab-infrastructure` (decommissioned).
- `src/pc_demo/`, `src/pc_monitor/` — Lambda handler Python source + prebuilt `.zip` artifacts for the two POC functions.
- `ssm_template/` — per-function SSM config templates (e.g. `pc_demo.json`).
- `pipelines/azure-pipelines-terraform-checks.yml` — CI pipeline (Azure DevOps — there is no `.github/workflows/` in this repo).
- `docs/terraform-checks.md` — tool reference doc explaining why each CI check exists and how to change it.
- `.tflint.hcl`, `.checkov.yaml` — linter/scanner config.

## CI/CD

Azure Pipelines, self-hosted `AWS-Agents` pool, single stage `TerraformChecks`, triggers on push to `develop`.

Steps: pinned `terraform fmt -check -recursive` / `init -backend=false` / `validate` in `envs/dev` → pinned TFLint 0.53.0 (`--recursive --minimum-failure-severity=error`) → pinned Checkov 3.2.257: advisory full scan (non-blocking) then a blocking gate on `CKV_AWS_40,1,62,63,355` (IAM/wildcard/public-bucket checks) → publishes a `terraform-checks-summary` artifact intended to drive a downstream Azure Classic Release pipeline (not yet built — see `docs/terraform-checks.md`'s mermaid diagram for the intended dev-plan/apply → approval → prod-plan/apply flow).

No `terraform apply` runs from this repo today; the pipeline is check-only.

For the reasoning behind specific lint/scan rule choices, read `docs/terraform-checks.md` rather than duplicating it here.
