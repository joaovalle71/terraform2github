# SOURCE_REPO: terraform2github
# TARGET_REPO: teste01
# BRANCH     : dev/translate
# repos ----------------
  variable "GITHUB_TOKEN" {
    description = "GitHub access token"
    type        = string
    sensitive   = true
  }
  variable "github_owner" {
    default   = "joaovalle71"
    type        = string
  }
