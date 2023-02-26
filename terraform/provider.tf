terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.29.0"
    }
  }

  backend "s3" {
    bucket = "hytssk-remote-tfstate"
    key    = "alb_experiments"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "self" {}

variable "prefix" {
  type    = string
  default = "hytssk-experiment"
}
