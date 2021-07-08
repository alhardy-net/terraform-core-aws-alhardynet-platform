resource "aws_acm_certificate" "ecs_domain_certificate" {
  domain_name               = var.ecs_alb_domain_name
  subject_alternative_names = ["*.${var.ecs_alb_domain_name}"]
  validation_method         = "EMAIL" // TODO: DNS validation currently hangs

  tags = {
    Name = var.ecs_alb_domain_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "ecs_domain" {
  name         = "${var.ecs_alb_domain_name}."
  private_zone = false
}

// TODO: Currently hands on DNS validation of certificate
//resource "aws_route53_record" "cert_validation" {
//  for_each = {
//    for ecs in aws_acm_certificate.ecs_domain_certificate.domain_validation_options : ecs.domain_name => {
//      name   = ecs.resource_record_name
//      record = ecs.resource_record_value
//      type   = ecs.resource_record_type
//    }
//  }
//
//  allow_overwrite = true
//  name            = each.value.name
//  records         = [each.value.record]
//  ttl             = 60
//  type            = each.value.type
//  zone_id         = data.aws_route53_zone.ecs_domain.zone_id
//}
//
//resource "aws_acm_certificate_validation" "ecs_domain_certificate_validation" {
//  certificate_arn         = aws_acm_certificate.ecs_domain_certificate.arn
//  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
//
//  timeouts {
//    create = "10m"
//  }
//}