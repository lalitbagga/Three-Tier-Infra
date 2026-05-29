terraform {
  # Explicitly defaults to a local state file saved right inside this folder.
  backend "local" {} 
}
provider "aws" {
  region = var.aws_region
}

# The remote state bucket
resource "aws_s3_bucket" "tf_state" {
  bucket        = "three-tier-tf-state-${var.aws_region}"
  force_destroy = false
  object_lock_enabled = true
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "tf_state" {
    bucket = aws_s3_bucket.tf_state.id
    rule {
        default_retention {
            mode = "GOVERNANCE"
            days = 1
        }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
