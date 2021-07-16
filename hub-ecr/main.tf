locals {
  image_names = ["service-bff", "service-customers"]
}

data "aws_iam_role" "ecr_full_access" {
  name = "EcrFullAccessRole"
}

data "aws_iam_role" "ecr_readonly_readonly" {
  name = "EcrReadonlyAccessRole"
}

data "aws_iam_policy_document" "resource_readonly_access" {
  statement {
    sid    = "ReadonlyAccess"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [data.aws_iam_role.ecr_readonly_readonly.arn]
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
    ]
    
    condition {
      test = "StringLike"
      values = ["o-2freyh0vsj/*"]
      variable = "aws:PrincipalOrgPaths"
    }
  }
}

data "aws_iam_policy_document" "resource_full_access" {

  statement {
    sid    = "FullAccess"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [data.aws_iam_role.ecr_full_access.arn]
    }

    actions = ["ecr:*"]
  }
}

module "ecr" {
  source                     = "cloudposse/ecr/aws"
  version                    = "0.32.2"
  namespace                  = "alhardynet"
  image_names                = local.image_names
  //principals_full_access     = [data.aws_iam_role.ecr_full_access.arn]
  //principals_readonly_access = [data.aws_iam_role.ecr_readonly_readonly.arn]
}

data "aws_iam_policy_document" "resource" {
  source_json   = join("", [data.aws_iam_policy_document.resource_readonly_access.json])
  override_json = join("", [data.aws_iam_policy_document.resource_full_access.json])
}

resource "aws_ecr_repository_policy" "name" {
  for_each   = toset(local.image_names)
  repository = each.value
  policy     = join("", data.aws_iam_policy_document.resource.*.json)
}

resource "aws_iam_role_policy_attachment" "attach_ecr_full_access" {
  role       = data.aws_iam_role.ecr_full_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "attach_ecr_readonly_access" {
  role       = data.aws_iam_role.ecr_readonly_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}