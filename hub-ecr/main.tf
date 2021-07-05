module "ecr" {
  source  = "cloudposse/ecr/aws"
  version = "0.32.2"
  namespace = "alhardynet"
}