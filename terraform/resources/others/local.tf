####################################################
# locals
####################################################
locals {
  app_name = "experiment"
  aws_vpc = {
    this = {
      id = "vpc-0c2811e3cb30e50c3"
    }
  }
  aws_subnet = {
    public_1a = {
      id = "subnet-0c29a100c510d9e41"
    }
    public_1c = {
      id = "subnet-0e9af49132dfdee23"
    }
  }
}

data "aws_caller_identity" "self" {}

variable "prefix" {
  type    = string
  default = "hytssk-experiment"
}
