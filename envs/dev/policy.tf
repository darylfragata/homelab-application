# Named, reusable IAM policies, one data "aws_iam_policy_document" block each.
# A function opts into any of these by name via its `permission` list
# (envs/dev/locals.tf). A policy shared by multiple functions is defined once
# here and just listed wherever it's needed.

# Example: cloudwatch:PutMetricData has no resource-level permissions in IAM
# (always Resource "*"), so this is a good "common" policy to demonstrate -
# any function that wants to emit custom metrics can opt in by name.
data "aws_iam_policy_document" "cloudwatch_put_metrics" {
  statement {
    sid       = "PutCustomMetrics"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

locals {
  policy_documents = {
    cloudwatch_put_metrics = data.aws_iam_policy_document.cloudwatch_put_metrics.json
  }
}
