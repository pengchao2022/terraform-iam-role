provider "aws" {
  region = var.aws_region
}

# 获取当前 AWS 账户 ID
data "aws_caller_identity" "current" {}

# 尝试获取已存在的 OIDC Provider
data "aws_iam_openid_connect_provider" "existing" {
  url = "https://token.actions.githubusercontent.com"
}

# 创建 OIDC Provider（如果不存在）
resource "aws_iam_openid_connect_provider" "github_actions" {
  count = data.aws_iam_openid_connect_provider.existing.id == null ? 1 : 0
  
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  
  tags = {
    Name = "github-actions-oidc"
  }
}

# 尝试获取已存在的 IAM Role
data "aws_iam_role" "existing" {
  name = "MyGitHubActionsRole"
}

# 创建 IAM Role（如果不存在）
resource "aws_iam_role" "github_actions_role" {
  count = data.aws_iam_role.existing.id == null ? 1 : 0
  
  name = "MyGitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = try(
            aws_iam_openid_connect_provider.github_actions[0].arn,
            data.aws_iam_openid_connect_provider.existing.arn
          )
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:pengchao2022/*"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "MyGitHubActionsRole"
  }
}

# 创建 Policy Attachment（如果不存在）
resource "aws_iam_role_policy_attachment" "github_actions_role_policy" {
  count = data.aws_iam_role.existing.id == null ? 1 : 0
  
  role       = aws_iam_role.github_actions_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 输出（自动选择新创建或已存在的）
output "github_role_arn" {
  value = try(
    aws_iam_role.github_actions_role[0].arn,
    data.aws_iam_role.existing.arn
  )
}

output "github_role_name" {
  value = try(
    aws_iam_role.github_actions_role[0].name,
    data.aws_iam_role.existing.name
  )
}

output "oidc_provider_arn" {
  value = try(
    aws_iam_openid_connect_provider.github_actions[0].arn,
    data.aws_iam_openid_connect_provider.existing.arn
  )
}