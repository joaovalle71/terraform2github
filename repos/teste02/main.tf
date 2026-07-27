# SOURCE_REPO: terraform2github
# TARGET_REPO: teste02
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
    name        = "teste02"
    description = "script para extrair dados via API do github e gera comandos terraform correspondentes "
    visibility  = "public"
    auto_init   = true
  }
# secrets ----------------
  resource "github_actions_secret" "SEC_GITHUB_TOKEN" {
    repository       = github_repository.repo.name
    secret_name      = "SEC_GITHUB_TOKEN"
    plaintext_value  = var.SEC_GITHUB_TOKEN
  }
# variables ----------------
  resource "github_actions_variable" "TERRAFORM_VERSION" {
    repository       = github_repository.repo.name
    variable_name    = "TERRAFORM_VERSION"
    value            = "6.13.0"
  }
# branches ----------------
    resource "github_branch" "teste02_main" {
    repository = github_repository.repo.name
    branch     = "main"
    }
