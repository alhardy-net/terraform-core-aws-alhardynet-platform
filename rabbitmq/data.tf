data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-networking-vpc-${local.env}"
    }
  }
}

data "terraform_remote_state" "hub" {
  backend = "remote"
  config = {
    organization = "bytebox"
    workspaces = {
      name = "core-aws-alhardynet-networking-hub-prod"
    }
  }
}