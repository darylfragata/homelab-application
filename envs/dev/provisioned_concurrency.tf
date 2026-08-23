# Per-function Provisioned Concurrency config, keyed by function name. Only
# consulted for functions with provisioned_concurrency = true
# (envs/dev/locals.tf) - a function with provisioned_concurrency = true but
# no entry here fails fast in main.tf's lookup. scheduled_actions is optional
# per entry - leave it [] for a plain static PC count with no time-based
# changes.
locals {
  provisioned_concurrency_config = {
    pc_demo = {
      base_capacity = 1
      scheduled_actions = [
        {
          name     = "scale-up-business-hours"
          schedule = "cron(0 8 ? * MON-FRI *)"
          capacity = 3
        },
        {
          name     = "scale-down-evenings"
          schedule = "cron(0 18 ? * MON-FRI *)"
          capacity = 1
        }
      ]
    }
  }
}
