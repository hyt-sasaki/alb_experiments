data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/daily_use"]
    }
  }
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:hyt-sasaki/alb_experiments:*"]
    }
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::hytssk-remote-tfstate/alb_experiments/*"]
  }
}

resource "aws_iam_role" "plan_assume_role" {
  name = "terraform_plan_assume_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "plan_policy" {
  name = "terraform_plan_policy"
  role = aws_iam_role.plan_assume_role.id
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_policy_attachment" "read_only" {
  name = "readonly_policy_for_terraform"
  roles = [aws_iam_role.plan_assume_role.id]
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}