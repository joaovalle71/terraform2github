#!/usr/bin/bash
#
# Extracts data from GitHub
#
# Functions used during the extraction process
if [[ -z $GITHUB_WORKSPACE ]]; then
    $GITHUB_WORKSPACE=.
fi
. $GITHUB_WORKSPACE/functions.sh
#
# uncomment for local test
# export GITHUB_TOKEN=XXXXXXX
# export GITHUB_WORKSPACE=$(pwd)
# cd ${GITHUB_WORKSPACE}
# echo $PATH
# pwd
# ls -latr
# whoami

# PARAMETERS
if [[ ! -z $1 ]]; then
    GLOBAL_EXTRACTION=$1
fi
if [[ "$GLOBAL_EXTRACTION" != "true" && "$GLOBAL_EXTRACTION" != "false" ]]; then
    echo "Incorrect execution parameters"
    exit 1
fi
if [[ ! -z $2 ]]; then
    TXT2TSV=$2
fi
if [[ "$TXT2TSV" != "true" && "$TXT2TSV" != "false" ]]; then
    echo "Incorrect execution parameters"
    exit 1
fi

if [[ -z $REPOSITORY ]] && [[ ! -z $3 ]]; then 
    REPOSITORY=$3
fi

rm -f *.txt*
#
# This script may make intensive use of the API, which can hit rate limits in some cases
# Displays user/token data and rate limit statistics before starting execution
# See limits at https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
#
if [[ "$DEBUG" == "true" ]]; then
    echo "$(date '+%Y%m%d %H:%M:%S') Show Rate Limits -----------------------------------------------"
    github_api "rate" "https://api.github.com/rate_limit"
fi
echo "$(date '+%Y%m%d %H:%M:%S') Show Current User -----------------------------------------------"
result="$(github_api "user" "https://api.github.com/user")"
if [[ $(echo "$result"|grep -c "var_repo_error=") -gt 0 ]]; then
    echo "$result"
    exit 1
else 
    echo "$result"|grep -E "^var_user_login"
fi

if [[ "${repo_source_owner_type}" == "User" ]]; then
    export GITHUB_REPOSITORY_TYPE="users"
else
    export GITHUB_REPOSITORY_TYPE="orgs"
fi

# extracts list of repositories using the github api
echo "$(date '+%Y%m%d %H:%M:%S') Extracting repos data -----------------------------------------------"
github_api "repo" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/repos"|grep -E "${REPOSITORY}">repos.txt &

if [[ "${GLOBAL_EXTRACTION}" == "true" ]]; then
    echo "$(date '+%Y%m%d %H:%M:%S') extracting global data -----------------------------------------------"
    if [[ $(grep -c 'var_repo_status="' repos.txt) -gt 0 ]]; then echo "ERROR!";cat repos.txt;exit;fi
    github_api "team" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/teams">teams.txt &
    github_api "outside_collaborator" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/outside_collaborators">outside_collaborators.txt &
    github_api "hook" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/hooks"|grep -v "var_hook_error=">hooks.txt &
    github_api "alert" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/dependabot/alerts">alerts.txt &
    github_api "member" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/members">members.txt &
    github_api "ruleset" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/rulesets">rulesets.txt &
    github_api "secret" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/actions/secrets">secrets.txt &
    github_api "variable" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/actions/variables">variables.txt &
    github_api "permission" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/actions/permissions">permissions.txt &
    github_api "alert" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/code-scanning/alerts">alerts.txt &
    github_api "security-advisory" "https://api.github.com/${GITHUB_REPOSITORY_TYPE}/${GITHUB_REPOSITORY_OWNER}/security-advisories">security-advisories.txt &
fi
#
wait
#
# loop to extract data from repositories
echo "$(date '+%Y%m%d %H:%M:%S') Extracting data associated with each repo -------------------------------------------"
[[ -f repos.txt ]] && while read -r repo && [[ ! -z $repo ]]; do
  eval $repo
  if [[ "$DEBUG" == "true" ]]; then echo "$var_repo_full_name"; fi
  github_api "env" "https://api.github.com/repos/${var_repo_full_name}/environments"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_environments.txt.$! &
  github_api "var" "https://api.github.com/repos/${var_repo_full_name}/actions/variables"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_variables.txt.$! &
  github_api "sec" "https://api.github.com/repos/${var_repo_full_name}/actions/secrets"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_secrets.txt.$! &
  github_api "branch" "https://api.github.com/repos/${var_repo_full_name}/branches"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_branches.txt.$! &
  github_api "ruleset" "https://api.github.com/repos/${var_repo_full_name}/rulesets"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_rulesets.txt.$! &
  github_api "release" "https://api.github.com/repos/${var_repo_full_name}/releases"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_releases.txt.$! &
  github_api "workflow" "https://api.github.com/repos/${var_repo_full_name}/actions/workflows"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_workflows.txt.$! &
  github_api "run" "https://api.github.com/repos/${var_repo_full_name}/actions/runs"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_runs.txt.$! &
  github_api "repo_alert" "https://api.github.com/repos/${var_repo_full_name}/code-scanning/alerts"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_alerts.txt.$! &
  github_api "pull" "https://api.github.com/repos/${var_repo_full_name}/pulls"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_pulls.txt.$! &
  github_api "security-advisory" "https://api.github.com/repos/${var_repo_full_name}/security-advisories"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_security-advisories.txt.$! &
  github_api "hook" "https://api.github.com/repos/${var_repo_full_name}/hooks"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_hooks.txt.$! &
  github_api "tag" "https://api.github.com/repos/${var_repo_full_name}/tags"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_tags.txt.$! &
  github_api "alert" "https://api.github.com/repos/${var_repo_full_name}/dependabot/alerts"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_alerts.txt.$! &
  github_api "issue" "https://api.github.com/repos/${var_repo_full_name}/issues"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_issues.txt.$! &
  github_api "key" "https://api.github.com/repos/${var_repo_full_name}/keys"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_keys.txt.$! &
  github_api "project" "https://api.github.com/repos/${var_repo_full_name}/projects"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_projects.txt.$! &
  github_api "usage" "https://api.github.com/repos/${var_repo_full_name}/actions/usage"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|"|grep -v "var_usage_error=">repo_usage.txt.$! &
  github_api "label" "https://api.github.com/repos/${var_repo_full_name}/labels"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|"|grep -v "var_usage_error=">repo_labels.txt.$! &
  github_api "team" "https://api.github.com/repos/${var_repo_full_name}/teams"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|"|grep -v "var_usage_error=">repo_teams.txt.$! &
  github_api "collaborator" "https://api.github.com/repos/${var_repo_full_name}/collaborators?affiliation=direct"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|"|grep -v "var_usage_error=">repo_collaborators.txt.$! &
  # repo x projects uses graphql
  # repo_projects.txt
  curl -s -L \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{ "query": "query { repository(owner: \"'${GITHUB_REPOSITORY_OWNER}'\", name: \"'${var_repo_name}'\") { projectsV2(first: 100) { nodes { id, title, url, public, shortDescription, createdAt, updatedAt, creator { login } } } } }" }' \
    "https://api.github.com/graphql"|format_json2 "var_repo_project" ";$(echo -e "\t")"|agg|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|"|grep -v "var_usage_error=">repo_projects.txt.$! &
  #
  # github_api "commit" "https://api.github.com/repos/${var_repo_full_name}/commits"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_commits.txt.$! &
  #
  # controls paralelism to avoid hitting API rate limits
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  eval $(set|grep -e "^var_repo_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done<<<$(grep -E "${REPOSITORY}" repos.txt)
#
wait
# join files with the same name and remove temporary files
while read -r filename; do
  find . -maxdepth 1 -type f -regex "${filename}\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \; &
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
done<<<$(find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]"|cut -d'.' -f1|sort -u)
#
wait
#
echo "$(date '+%Y%m%d %H:%M:%S') Extracting data from environments -------------------------"
[[ -f repo_environments.txt ]] && while read -r env && [[ ! -z $env ]]; do
  eval $env
  if [[ "$DEBUG" == "true" ]]; then echo "$var_repo_full_name;$var_env_environments_name"; fi
  github_api "env_rule" "https://api.github.com/repos/${var_repo_full_name}/environments/${var_env_environments_name}/deployment_protection_rules"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_env_environments_name=\"${var_env_environments_name}\";\t|">env_rules.txt.$! &
  github_api "env_var" "https://api.github.com/repos/${var_repo_full_name}/environments/${var_env_environments_name}/variables"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_env_environments_name=\"${var_env_environments_name}\";\t|">env_variables.txt.$! &
  github_api "env_sec" "https://api.github.com/repos/${var_repo_full_name}/environments/${var_env_environments_name}/secrets"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_env_environments_name=\"${var_env_environments_name}\";\t|">env_secrets.txt.$! &
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  eval $(set|grep -e "^var_env_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done < repo_environments.txt
#
wait
# join files with the same name and remove temporary files
find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \;
#
echo "$(date '+%Y%m%d %H:%M:%S') Extracting rulesets from repos -------------------------"
[[ -f repo_rulesets.txt ]] && while read -r repo_ruleset && [[ ! -z $repo_ruleset ]]; do
    eval $repo_ruleset
    if [[ "$DEBUG" == "true" ]]; then echo "$var_repo_full_name;$var_ruleset_name"; fi
    if [[ ! -z "${var_ruleset_name}" ]]; then
        { github_api "ruleset_detail" "https://api.github.com/repos/${var_repo_full_name}/rulesets/${var_ruleset_id}" list|tr -d '\n'|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_ruleset_name=\"${var_ruleset_name}\";\t|";echo ""; }|grep -v "var_repo_ruleset_detail_error=">repo_ruleset_detail.txt.$! &
    fi
    eval $(set|grep -e "^var_ruleset_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done < repo_rulesets.txt
#
wait
# join files with the same name and remove temporary files
find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \;
#
echo "$(date '+%Y%m%d %H:%M:%S') Extracting branch protection from repos ----------------------"
[[ -f repo_branches.txt ]] && while read -r branch && [[ ! -z $branch ]] ; do
  eval $branch
  if [[ "$DEBUG" == "true" ]]; then echo "$var_repo_full_name;$var_branch_name"; fi
  { github_api "branch_protection" "https://api.github.com/repos/${var_repo_full_name}/branches/${var_branch_name}/protection" list|tr -d '\n'|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_branch_name=\"${var_branch_name}\";\t|";echo ""; }>branch_protection.txt.$! &
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  eval $(set|grep -e "^var_branch_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done < repo_branches.txt
#
wait
# join files with the same name and remove temporary files
find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \;
#
# convert txt files to tsv files if TXT2TSV is true
if [[ "${TXT2TSV}" == "true" ]]; then
  echo "$(date '+%Y%m%d %H:%M:%S') Converting TXT files to TSV -----------------------------------"
  while read -r file && [[ ! -z $file ]] ; do
    txt2tsv < "$file" > "${file%.*}.tsv" &
    while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  done<<<$(find . -maxdepth 1 -type f -regex ".*\.txt")
  wait
fi
#
echo "$(date '+%Y%m%d %H:%M:%S') Execution completed ----------------------------------------------"

