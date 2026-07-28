# SOURCE_REPO: terraform2github
# TARGET_REPO: teste01
# BRANCH     : dev/translate
# repos ----------------
  import {
    to = github_repository.repo
    id = "teste01"
  }
# secrets ----------------
  import {
    to = github_actions_secret.SEC_GITHUB_TOKEN
    id ="teste01:SEC_GITHUB_TOKEN"
  }
# variables ----------------
  import {
    to = github_actions_variable.TERRAFORM_VERSION
    id = "teste01:TERRAFORM_VERSION"
  }
# branches ----------------
  import {
    to = github_branch.teste01_dev-translate
    id = "teste01:dev/translate"
  }
# branches ----------------
  import {
    to = github_branch.teste01_main
    id = "teste01:main"
  }
