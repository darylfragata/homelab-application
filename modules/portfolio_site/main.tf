resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

  tags = {
    Name = "${var.environment}-${var.project_name}-portfolio-site"
  }
}

# Static website hosting is what makes the bucket directly browsable over
# plain HTTP - this is the origin Cloudflare will proxy later, replacing the
# CloudFront+OAC approach used by homelab-infrastructure's now-decommissioned
# static_site module.
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# A public-read bucket policy requires block_public_policy and
# restrict_public_buckets to both be false - set explicitly here rather than
# omitting this resource, so the bucket doesn't silently depend on AWS's
# account-level public-access defaults.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "site" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json

  depends_on = [aws_s3_bucket_public_access_block.site]
}
