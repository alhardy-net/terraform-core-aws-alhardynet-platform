terraform {
  backend "remote" {
    organization = "bytebox"

    workspaces {
      prefix = "core-aws-alhardynet-platform-hub-ecr-"
    }
  }
}