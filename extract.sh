#!/usr/bin/bash
#
# Executa extracao de dados do github
#
# Funcoes utilizadas no processo de extracao
if [[ -z $GITHUB_WORKSPACE ]]; then
    $GITHUB_WORKSPACE=.
fi
. $GITHUB_WORKSPACE/functions.sh
#
# descomentar para testes locais
# export GITHUB_TOKEN=XXXXXXX
# export GITHUB_WORKSPACE=$(pwd)
# cd ${GITHUB_WORKSPACE}
# echo $PATH
# pwd
# ls -latr
# whoami

if [[ ! -z $1 ]]; then
    EXTRACAO_GLOBAL=$1
fi
if [[ "$EXTRACAO_GLOBAL" != "true" && "$EXTRACAO_GLOBAL" != "false" ]]; then
    echo "Parametros de execucao incorretos"
    exit 1
fi
if [[ ! -z $2 ]]; then
    TXT2TSV=$2
fi
if [[ "$TXT2TSV" != "true" && "$TXT2TSV" != "false" ]]; then
    echo "Parametros de execucao incorretos"
    exit 1
fi

if [[ -z $REPOSITORIO ]] && [[ ! -z $3 ]]; then 
    REPOSITORIO=$3
fi

rm -f *.txt*
#
# Esta api pode fazer uso intensivo da API que pode atingir os limites de uso em alguns casos
# Exibe dados do usuario/token e estatisticas dos limites antes de iniciar a execucao
# Vide limites em https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28
#
if [[ "$DEBUG" == "true" ]]; then
    echo "$(date '+%Y%m%d %H:%M:%S') rates -----------------------------------------------"
    github_api "rate" "https://api.github.com/rate_limit"
fi
echo "$(date '+%Y%m%d %H:%M:%S') current user -----------------------------------------------"
result="$(github_api "user" "https://api.github.com/user")"
if [[ $(echo "$result"|grep -c "var_repo_error=") -gt 0 ]]; then
    echo "$result"
    exit 1
fi
if [[ "$DEBUG" == "true" ]]; then
    echo "$result"
else
    echo "$result"|grep -E "^var_user_login"
fi

#extrai lista de repositorios usando api do github
echo "$(date '+%Y%m%d %H:%M:%S') extraindo repos -----------------------------------------------"
github_api "repo" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/repos"|grep -E "${REPOSITORIO}">repos.txt &

# if [[ ! -z "$REPOSITORIO" ]]; then
#     { github_api "repo" "https://api.github.com/repos/${GITHUB_REPOSITORY_OWNER}/${REPOSITORIO}"|tr '\n' '\t' ; echo ""; }>repos.txt &
# else
#     github_api "repo" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/repos">repos.txt &
# fi
if [[ "${EXTRACAO_GLOBAL}" == "true" ]]; then
    echo "$(date '+%Y%m%d %H:%M:%S') extraindo dados globais -----------------------------------------------"
    if [[ $(grep -c 'var_repo_status="' repos.txt) -gt 0 ]]; then echo "ERROR!";cat repos.txt;exit;fi
    github_api "team" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/teams">teams.txt &
    github_api "outside_collaborator" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/outside_collaborators">outside_collaborators.txt &
    github_api "hook" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/hooks"|grep -v "var_hook_error=">hooks.txt &
    github_api "alert" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/dependabot/alerts">alerts.txt &
    github_api "member" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/members">members.txt &
    github_api "ruleset" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/rulesets">rulesets.txt &
    github_api "secret" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/actions/secrets">secrets.txt &
    github_api "variable" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/actions/variables">variables.txt &
    github_api "permission" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/actions/permissions">permissions.txt &
    github_api "alert" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/code-scanning/alerts">alerts.txt &
    github_api "security-advisory" "https://api.github.com/orgs/${GITHUB_REPOSITORY_OWNER}/security-advisories">security-advisories.txt &
fi
wait
#
#loop para extrair dados dos repositorios
echo "$(date '+%Y%m%d %H:%M:%S') Extraindo dados associados a cada repos -------------------------------------------"
while read -r repo && [[ ! -z $repo ]]; do
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
  #repo x projects usa graphql
  curl -s -L \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{ "query": "query { repository(owner: \"'${GITHUB_REPOSITORY_OWNER}'\", name: \"'${var_repo_name}'\") { projectsV2(first: 100) { nodes { id, title, url, public, shortDescription, createdAt, updatedAt, creator { login } } } } }" }' \
    "https://api.github.com/graphql"|format_json2 "var_repo_project" ";$(echo -e "\t")"|agg|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|"|grep -v "var_usage_error=">repo_projects.txt.$! &
  # github_api "commit" "https://api.github.com/repos/${var_repo_full_name}/commits"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\t|">repo_commits.txt.$! &
  #
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  eval $(set|grep -e "^var_repo_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done<<<$(grep -E "${REPOSITORIO}" repos.txt)
wait
while read -r filename; do
  find . -maxdepth 1 -type f -regex "${filename}\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \; &
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
done<<<$(find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]"|cut -d'.' -f1|sort -u)
wait
echo "$(date '+%Y%m%d %H:%M:%S') Extraindo dados dos enviroments -------------------------"
while read -r env && [[ ! -z $env ]]; do
  eval $env
  if [[ "$DEBUG" == "true" ]]; then echo "$var_repo_full_name;$var_env_environments_name"; fi
  github_api "env_rule" "https://api.github.com/repos/${var_repo_full_name}/environments/${var_env_environments_name}/deployment_protection_rules"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_env_environments_name=\"${var_env_environments_name}\";\t|">env_rules.txt.$! &
  github_api "env_var" "https://api.github.com/repos/${var_repo_full_name}/environments/${var_env_environments_name}/variables"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_env_environments_name=\"${var_env_environments_name}\";\t|">env_variables.txt.$! &
  github_api "env_sec" "https://api.github.com/repos/${var_repo_full_name}/environments/${var_env_environments_name}/secrets"|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_env_environments_name=\"${var_env_environments_name}\";\t|">env_secrets.txt.$! &
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  eval $(set|grep -e "^var_env_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done < repo_environments.txt
wait
find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \;
echo "$(date '+%Y%m%d %H:%M:%S') Extraindo rulesets dos repos -------------------------"
while read -r repo_ruleset && [[ ! -z $repo_ruleset ]]; do
    eval $repo_ruleset
    if [[ "$DEBUG" == "true" ]]; then echo "$var_repo_full_name;$var_ruleset_name"; fi
    if [[ ! -z "${var_ruleset_name}" ]]; then
        { github_api "ruleset_detail" "https://api.github.com/repos/${var_repo_full_name}/rulesets/${var_ruleset_id}" list|tr -d '\n'|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_ruleset_name=\"${var_ruleset_name}\";\t|";echo ""; }|grep -v "var_repo_ruleset_detail_error=">repo_ruleset_detail.txt.$! &
    fi
    eval $(set|grep -e "^var_ruleset_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done < repo_rulesets.txt
wait
find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \;
#
echo "$(date '+%Y%m%d %H:%M:%S') Extraindo branch protection dos repos ----------------------"
while read -r branch && [[ ! -z $branch ]] ; do
  eval $branch
  if [[ "$DEBUG" == "true" ]]; then echo "$var_repo_full_name;$var_branch_name"; fi
  { github_api "branch_protection" "https://api.github.com/repos/${var_repo_full_name}/branches/${var_branch_name}/protection" list|tr -d '\n'|sed "s|^|var_repo_full_name=\"${var_repo_full_name}\";\tvar_branch_name=\"${var_branch_name}\";\t|";echo ""; }>branch_protection.txt.$! &
  while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  eval $(set|grep -e "^var_branch_"|cut -d"=" -f1|sed -z 's/\n/;/g;s/var_/unset var_/g')
done < repo_branches.txt
wait
find . -maxdepth 1 -type f -regex ".*\.txt\..*[0-9]" -exec bash -c 'cat {}>>$(echo {}|sed "s/\.txt\.[^\.txt\.]*$/.txt/");rm {}' \;
#
if [[ "${TXT2TSV}" == "true" ]]; then
  echo "$(date '+%Y%m%d %H:%M:%S') Transforma arquivos TXT em TSV -----------------------------------"
  while read -r file && [[ ! -z $file ]] ; do
    txt2tsv < "$file" > "${file%.*}.tsv" &
    while [ $(jobs -rp| wc -l) -ge 30 ]; do sleep 1; done
  done<<<$(find . -maxdepth 1 -type f -regex ".*\.txt")
  wait
fi
echo "$(date '+%Y%m%d %H:%M:%S') Execucao finalizada ----------------------------------------------"
find . -maxdepth 1 -type f -regex ".*\.txt" -exec wc -l {} \;
