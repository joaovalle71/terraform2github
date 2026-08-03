# SOURCE_REPO: terraform2github
# TARGET_REPO: teste02
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
# secrets ----------------
  variable "REGISTRY_TOKEN" {
    type      = string
    sensitive = true
  }
# secrets ----------------
  variable "REGISTRY_USER" {
    type      = string
    sensitive = true
  }
# secrets ----------------
  variable "SEC_GITHUB_TOKEN" {
    type      = string
    sensitive = true
  }
