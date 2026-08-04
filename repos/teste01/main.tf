# SOURCE_REPO: terraform2github
# TARGET_REPO: teste01
# BRANCH     : dev/translate
# repos ----------------
  # main.tf
  terraform {
    required_providers {
      github = {
        source = "integrations/github"
        version = "6.13.0"
      }
    }
  }
  #
  resource "github_repository" "repo" {
    name        = "teste01"
    description = "script para extrair dados via API do github e gera comandos terraform correspondentes "
    visibility  = "public"
    auto_init   = true
  }
# variables ----------------
  resource "github_actions_variable" "REGISTRY_URL" {
    repository       = github_repository.repo.name
    variable_name    = "REGISTRY_URL"
    value            = "dockerhub.io"
  }
# variables ----------------
  resource "github_actions_variable" "TERRAFORM_VERSION" {
    repository       = github_repository.repo.name
    variable_name    = "TERRAFORM_VERSION"
    value            = "6.13.0"
  }
# variables ----------------
  resource "github_actions_variable" "VAR_GITHUB_AGENT" {
    repository       = github_repository.repo.name
    variable_name    = "VAR_GITHUB_AGENT"
    value            = "ubuntu-latest"
  }
# branches ----------------
    resource "github_branch" "teste01_dev-translate" {
    repository = github_repository.repo.name
    branch     = "dev/translate"
    }
# branches ----------------
    resource "github_branch" "teste01_main" {
    repository = github_repository.repo.name
    branch     = "main"
    }
