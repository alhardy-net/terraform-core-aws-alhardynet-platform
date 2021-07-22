aws_region                   = "ap-southeast-2"
aws_account_id               = "171101346296"
aws_assume_role              = "TerraformAccessRole"
ecs_nlb_domain_name          = "dev.alhardy.net"
private_namespace            = "alhardynet.local"
appmesh_name                 = "alhardynet"
envoy_image                  = "840364872350.dkr.ecr.ap-southeast-2.amazonaws.com/aws-appmesh-envoy:v1.18.3.0-prod"
xray_image                   = "amazon/aws-xray-daemon:1"
virtual_gateway              = { 
  service_name = "virtual-gateway-envoy",
  cpu = 256,
  memory = 512,
  desired_count = 1,
  max_percent = 200,
  min_percent = 100
} 
