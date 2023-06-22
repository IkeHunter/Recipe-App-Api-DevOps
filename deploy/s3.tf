resource "aws_s3_bucket" "app_public_files" {
  bucket        = "${local.prefix}-files"
  acl           = "public-read" # readable by public
  force_destroy = true          # allows tf to destroy
}



