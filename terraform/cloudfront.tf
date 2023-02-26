resource "aws_cloudfront_distribution" "static_hosting" {
  enabled = true

  # オリジンの設定 (S3)
  origin {
    origin_id   = aws_s3_bucket.static_hosting.id
    domain_name = aws_s3_bucket.static_hosting.bucket_regional_domain_name
    # OACを設定
    origin_access_control_id = aws_cloudfront_origin_access_control.static_hosting.id
  }
  # オリジンの設定 (ALB)
  origin {
    origin_id   = aws_lb.this.id
    domain_name = aws_route53_record.alb_https.fqdn
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # S3のキャッシュ戦略
  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.static_hosting.id
    viewer_protocol_policy = "redirect-to-https"
    cached_methods         = ["GET", "HEAD"]
    allowed_methods        = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }
  }

  # ALBのキャッシュ戦略
  ordered_cache_behavior {
    target_origin_id       = aws_lb.this.id
    path_pattern           = "/oauth2/*"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
    min_ttl     = 0
    default_ttl = 10
    max_ttl     = 60
  }

  ordered_cache_behavior {
    target_origin_id       = aws_lb.this.id
    path_pattern           = "/api/*"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET", "OPTIONS"]
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
    min_ttl     = 0
    default_ttl = 10
    max_ttl     = 60

    response_headers_policy_id = aws_cloudfront_response_headers_policy.alb_redirect_setting.id
  }

  default_root_object = "index.html"
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# OAC を作成
resource "aws_cloudfront_origin_access_control" "static_hosting" {
  name                              = "${var.prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "alb_redirect_setting" {
  name = "alb_redirect_cors_policy"
  cors_config {
    access_control_allow_credentials = false
    origin_override                  = true
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD"]
    }
    access_control_allow_origins {
      items = ["https://d3ursguoush4q6.cloudfront.net"]
    }
  }
}