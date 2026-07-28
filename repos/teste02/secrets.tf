# SOURCE_REPO: terraform2github
# TARGET_REPO: teste02
# BRANCH     : dev/translate
# repos ----------------
  variable "github_token" {
    description = "GitHub access token"
    type        = string
    sensitive   = true
    default   = "$GITHUB_TOKEN"
  }
  variable "github_owner" {
    default   = "joaovalle71"
    type        = string
  }
# secrets ----------------
  variable "SEC_GITHUB_TOKEN" {
    default   = "$SEC_GITHUB_TOKEN"
    sensitive = true
  }
