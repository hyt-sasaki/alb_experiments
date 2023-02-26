####################################
# S3 Bucket
####################################
resource "aws_s3_bucket" "static_hosting" {
  bucket        = "${var.prefix}-static-hosting-pipeline"
  force_destroy = true
}

# サーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.static_hosting.id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# ACL無効化
resource "aws_s3_bucket_ownership_controls" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# バケットポリシー
resource "aws_s3_bucket_policy" "static_hosting" {
  bucket = aws_s3_bucket.static_hosting.id
  policy = data.aws_iam_policy_document.bucket_static_hosting.json
}

data "aws_iam_policy_document" "bucket_static_hosting" {
  version = "2012-10-17"
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_hosting.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.static_hosting.arn]
    }
  }
}

# パブリックブロックアクセス
resource "aws_s3_bucket_public_access_block" "static_hosting" {
  bucket                  = aws_s3_bucket.static_hosting.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket_policy.static_hosting,
    aws_s3_bucket_ownership_controls.static_hosting
  ]
}


# ALBログ用バケットの作成
# 参考 https://dev.classmethod.jp/articles/alb-s3-bucket-policy-terraform/
data "aws_elb_service_account" "elb_service_account" {}
data "aws_caller_identity" "caller_identity" {}
#ALBログ用プレフィックスの設定
variable "alb_log_prefix" {
  default = "alb-access-log" #任意の名前
}
resource "aws_s3_bucket" "bucket_alb_log" {
  bucket = "${var.alb_log_prefix}-${data.aws_caller_identity.caller_identity.account_id}"
}

data "aws_iam_policy_document" "tf_iam_policy_document_alb_log" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.elb_service_account.id]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket_alb_log.bucket}/AWSLogs/${data.aws_caller_identity.caller_identity.account_id}/*"]
    // resources = ["arn:aws:s3:::${aws_s3_bucket.bucket_alb_log.bucket}/*"]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket_alb_log.bucket}/AWSLogs/${data.aws_caller_identity.caller_identity.account_id}/*"]
    // resources = ["arn:aws:s3:::${aws_s3_bucket.bucket_alb_log.bucket}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket_alb_log.bucket}"]
  }
}

#バケットポリシーの書き換え
resource "aws_s3_bucket_policy" "tf_bucket_policy_alb_log" {
  bucket = aws_s3_bucket.bucket_alb_log.id
  policy = data.aws_iam_policy_document.tf_iam_policy_document_alb_log.json
}