####################################################
# ALB Security Group
####################################################
resource "aws_security_group" "alb" {
  name        = "${local.app_name}-integrated-alb"
  description = "${local.app_name} alb rule based routing"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    protocol    = "-1" # あとで調べる
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.app_name}-integrated-alb"
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

//resource "aws_security_group_rule" "alb_http" {
//  security_group_id = aws_security_group.alb.id
//  type              = "ingress"
//  protocol          = "tcp"
//  from_port         = 80
//  to_port           = 80
//  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
//}

resource "aws_security_group_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}

resource "aws_lb" "this" {
  name               = "${local.app_name}-integrated-alb"
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = [
    var.public_1a_subnet_id,
    var.public_1c_subnet_id,
  ]
  access_logs {
    bucket  = aws_s3_bucket.bucket_alb_log.bucket
    enabled = true
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  # ACM証明書をHTTPSリスナーに関連づけ
  certificate_arn = aws_acm_certificate.cert.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "503 Service Temporarily Unavailable"
      status_code  = "503"
    }
  }
  depends_on = [
    aws_acm_certificate_validation.validation
  ]
}

resource "aws_route53_record" "alb_https" {
  name    = "alb"
  type    = "A"
  zone_id = aws_route53_zone.main.zone_id
  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
