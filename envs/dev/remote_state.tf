# Read-only reference to homelab-infrastructure's dev state. One-directional:
# homelab-application reads homelab-infrastructure's outputs; the reverse never
# happens (see the pc_monitor_ssm_parameter_name variable wiring on the
# homelab-infrastructure side instead, which uses a plain agreed-upon string,
# not a remote_state read back into that repo).
data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "df-iac-tfstate"
    key    = "infra/dev/infrastructure.tfstate"
    region = "ap-southeast-1"
  }
}
