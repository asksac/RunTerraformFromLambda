#
# create s3 bucket and dynamodb table, used for storing state and lock files
# for the terraform module executed inside lambda 
#

resource "aws_s3_bucket" "tf_statefile_bucket" {
  bucket            = "${lower(var.app_shortcode)}-tf-statefile-${local.account_id}"
  acl               = "private"
  force_destroy     = true

  tags              = local.common_tags
}

resource "aws_dynamodb_table" "tf_lockfile_table" {
  name              = "${lower(var.app_shortcode)}-tf-lockfile"
  hash_key          = "LockID"
  read_capacity     = 5
  write_capacity    = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags              = local.common_tags
}