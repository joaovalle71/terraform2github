# SOURCE_REPO: terraform2github
# TARGET_REPO: teste03
# BRANCH     : main
# repos ----------------
  variable "github_token" {
    description = "Token de acesso ao GitHub"
    type        = string
    sensitive   = true
    default   = "$GITHUB_TOKEN"
  }
  variable "github_owner" {
    default   = "joaovalle71"
    type        = string
  }
# secrets ----------------
  variable "REGISTRY_TOKEN" {
    default   = "$REGISTRY_TOKEN"
    sensitive = true
  }
# secrets ----------------
  variable "REGISTRY_USER" {
    default   = "$REGISTRY_USER"
    sensitive = true
  }
# secrets ----------------
  variable "SEC_GITHUB_TOKEN" {
    default   = "$SEC_GITHUB_TOKEN"
    sensitive = true
  }
