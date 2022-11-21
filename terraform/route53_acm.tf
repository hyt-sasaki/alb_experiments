locals {
  domain_name = "hytssk.tk"
}
resource "aws_route53_zone" "main" {
  name = local.domain_name
}

resource "aws_acm_certificate" "cert" {
  # ワイルドカード証明書で同じドメイン内の複数のサイトを保護
  domain_name               = "*.${local.domain_name}"
  # ネイキッドドメインや apex ドメイン(ドメイン名そのもの)を保護
  subject_alternative_names = [local.domain_name]
  # ACMドメイン検証方法にDNS検証を指定
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  type = each.value.type
  ttl = "300"

  # レコードを追加するドメインのホストゾーンIDを指定
  zone_id = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
