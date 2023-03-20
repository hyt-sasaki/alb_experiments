####################################################
# locals
####################################################
locals {
  app_name = "experiment"
}

data "aws_caller_identity" "self" {}

variable "prefix" {
  type    = string
  default = "hytssk-experiment"
}
