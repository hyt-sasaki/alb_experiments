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
    actions = [
      "apigateway:GET",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:DescribeScheduledActions",
      "autoscaling:DescribeLaunchConfigurations",
      "cloudformation:DescribeStacks",
      "cloudformation:GetTemplate",
      "cloudfront:GetDistribution",
      "cloudfront:ListDistributions",
      "cloudfront:ListTagsForResource",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeGlobalTable",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTableReplicaAutoScaling",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceCreditSpecifications",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcs",
      "ec2:GetEbsEncryptionByDefault",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListTagsForResource",
      "elasticache:DescribeCacheClusters",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:GetUser",
      "iam:GetUserPolicy",
      "iam:ListAccessKeys",
      "iam:ListAttachedGroupPolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListGroupPolicies",
      "iam:ListGroups",
      "iam:ListPolicies",
      "iam:ListRolePolicies",
      "iam:ListRoles",
      "iam:ListUserPolicies",
      "iam:ListUsers",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListKeys",
      "kms:ListResourceTags",
      "lambda:GetEventSourceMapping",
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:ListEventSourceMappings",
      "lambda:ListFunctions",
      "lambda:ListVersionsByFunction",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeGlobalClusters",
      "rds:ListTagsForResource",
      "route53:GetHealthCheck",
      "route53:GetHostedZone",
      "route53:ListHealthChecks",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "s3:GetAccelerateConfiguration",
      "s3:GetAccountPublicAccessBlock",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "sns:GetSubscriptionAttributes",
      "sns:GetTopicAttributes",
      "sns:ListSubscriptions",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTagsForResource",
      "sns:ListTopics",
      "sqs:GetQueueAttributes",
      "sqs:ListQueues",
      "sqs:ListQueueTags"
    ]
    resources = ["*"]
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
