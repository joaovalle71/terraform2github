# SOURCE_REPO: terraform2github
# TARGET_REPO: teste02
# BRANCH     : main
# repos ----------------
  import {
    to = github_repository.repo
    id = "teste02"
  }
# secrets ----------------
  import {
    to = github_actions_secret.SEC_GITHUB_TOKEN
    id ="teste02:SEC_GITHUB_TOKEN"
  }
# branches ----------------
  import {
    to = github_branch.teste02_main
    id = "teste02:main"
  }
