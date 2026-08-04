# SOURCE_REPO: terraform2github
# TARGET_REPO: teste03
# BRANCH     : main
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
    name        = "teste03"
    description = "script para extrair dados via API do github e gera comandos terraform correspondentes "
    visibility  = "public"
    auto_init   = true
  }
# secrets ----------------
  resource "github_actions_secret" "REGISTRY_TOKEN" {
    repository       = github_repository.repo.name
    secret_name      = "REGISTRY_TOKEN"
    value            = var.REGISTRY_TOKEN
  }
# secrets ----------------
  resource "github_actions_secret" "REGISTRY_USER" {
    repository       = github_repository.repo.name
    secret_name      = "REGISTRY_USER"
    value            = var.REGISTRY_USER
  }
# secrets ----------------
  resource "github_actions_secret" "SEC_GITHUB_TOKEN" {
    repository       = github_repository.repo.name
    secret_name      = "SEC_GITHUB_TOKEN"
    value            = var.SEC_GITHUB_TOKEN
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
    resource "github_branch" "teste03_dev-translate" {
    repository = github_repository.repo.name
    branch     = "dev/translate"
    }
# branches ----------------
    resource "github_branch" "teste03_main" {
    repository = github_repository.repo.name
    branch     = "main"
    }
