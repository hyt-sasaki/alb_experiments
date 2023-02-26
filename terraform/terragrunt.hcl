terraform {
  source = "${path_relative_from_include()}//${local.target_dir}"
}

locals {
  target_dir = path_relative_to_include()
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "hytssk-remote-tfstate"

    key                       = "alb_experiments"
    region                    = "ap-northeast-1"
    skip_bucket_versioning    = true
    skip_bucket_ssencryption  = true
    skip_bucket_accesslogging = true
    skip_bucket_root_access   = true
    skip_bucket_enforced_tls  = true
  }
}