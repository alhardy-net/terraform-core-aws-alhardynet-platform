data "aws_iam_role" "ecr_full_access" {
  name = "EcrFullAccessRole"
}

data "aws_iam_role" "ecr_readonly_readonly" {
  name = "EcrReadonlyAccessRole"
}

module "ecr" {
  source                     = "cloudposse/ecr/aws"
  version                    = "0.32.2"
  namespace                  = "alhardynet"
  principals_full_access     = [data.aws_iam_role.ecr_full_access.arn]
  principals_readonly_access = [data.aws_iam_role.ecr_readonly_readonly.arn]
}