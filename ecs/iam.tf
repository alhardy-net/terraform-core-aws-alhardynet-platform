// Allow EC2 instance to register as ECS cluster member, fetch ECR images, write logs to CloudWatch
data "aws_iam_policy_document" "ec2_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  assume_role_policy = data.aws_iam_policy_document.ec2_instance_assume_role_policy.json
  name               = "EcsCluster${local.name}Ec2InstanceRole"
  tags = {
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

// Allow ECS service to interact with LoadBalancers
data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role_policy.json
  name               = "EcsCluster${local.name}ServiceRole"
  tags = {
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_iam_role_policy_attachment" "service_role" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs_task_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_policy.json
  name               = "EcsCluster${local.name}DefaultTaskRole"
  tags = {
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_iam_role_policy_attachment" "default_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "envoy_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "xray_task_role" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

data "aws_iam_policy_document" "allow_create_log_groups" {
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "allow_create_log_groups" {
  policy = data.aws_iam_policy_document.allow_create_log_groups.json
  role   = aws_iam_role.ecs_task_role.id
}

// Allows AWS autoscaling to inspect the stats and adjust scalable targets
data "aws_iam_policy_document" "ecs_autoscale_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_autoscale_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_autoscale_role_policy.json
  name               = "EcsCluster${local.name}AutoscaleRole"
  tags = {
    TerraformWorkspace = var.TFC_WORKSPACE_SLUG
  }
}

resource "aws_iam_role_policy_attachment" "ecs_autoscale_role" {
  role       = aws_iam_role.ecs_autoscale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}