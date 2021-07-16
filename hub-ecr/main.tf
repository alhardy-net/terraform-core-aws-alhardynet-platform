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
  image_names                = ["service-bff-api", "service-customers-api"]
  principals_full_access     = [data.aws_iam_role.ecr_full_access.arn]
  principals_readonly_access = [data.aws_iam_role.ecr_readonly_readonly.arn]
}

resource "aws_iam_role_policy_attachment" "attach_ecr_full_access" {
  role       = data.aws_iam_role.ecr_full_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_ecr_readonly_access" {
  role       = data.aws_iam_role.ecr_readonly_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}