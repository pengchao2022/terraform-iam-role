variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "IAM Role name"
  type        = string
  default     = "MyGitHubActionsRole"
}

variable "github_repo" {
  description = "GitHub repository (e.g., username/repo)"
  type        = string
  default     = ""  
}