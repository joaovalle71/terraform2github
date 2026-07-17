# terraform4github
## Permite extrair, sinconizar e clonar regras de repositórios github usando terraform
### Observação
* Estes pipelines permitem clonar estruturas, regras e configurações do github. Para conteúdo dos repositorios (fontes) vide o comando "git clone --mirror"
* Este script contempla a clonagem das seguintes configurações:
  - Repositório
  - Variáveis por repositorio
  - Secrets por repositorio
  - Environments
  - Environment rules
  - Variáveis por environment
  - Secrets por environment
  - Branches
  - Branch Protection (parcial)
---

### Estrutura de Pastas
* README.md - este arquivo
* .github/workflows/extract.yml - Pipeline para extrair dados gerais do github para analises
* .github/workflows/run_terraform.yml - Pipeline para extrair, criar e aplicar configurações terraform de repositorios
* extract.sh - script bash para extração de informações do github usando API REST
* functions.sh - funções auxiares utilizadas pelos scripts
* repos/<nome_do_repo> - diretorio que contém os scripts do projeto criados pelo pipeline terraform
* repos/<nome_do_repo>/main.tf - script terraform principal gerado pelo pipeline para aplicação de configurações no github
* repos/<nome_do_repo>/secret.tf - arquivo parametrizado com secrets para injetar valores usando as variaveis de ambiente do pipeline
* repos/<nome_do_repo>/import.tf - comandos de import gerado pelo pipeline para recuperar os arquivos tfstate dos repositórios existentes
---
![image](https://github.com/user-attachments/assets/dfe90d20-555b-4954-83f7-9e06d30c717d)
---

### Extração Geral
1. Escolha os parametros de execução
 * Branch - Branch onde sera executado o pipeline, pode manter na main
 * Extrai variaveis globais - Extrai os dados a nivel corporativo
 * Repositorio - Extrai dados de um repositorio especifico ou todos
 * Debug? - Aumenta nivel de depuração 
2. Verifique o resultado da execução nos anexos do pipeline
---
![image](https://github.com/user-attachments/assets/cdd3aed6-05af-4fd1-a340-aebbe5c689a7)
---
![image](https://github.com/user-attachments/assets/c450a67e-3a19-4982-9ff9-480c94f6ed24)
---
![image](https://github.com/user-attachments/assets/8163ad2b-f702-4b6b-8dab-4bd62a9b9a62)
---
### Execução do TERRAFORM
1. Crie uma branch de trabalho a partir da main para armazenar suas execuções
2. Selecione sua nova branch de trabalho para execução do pipeline
  * Branch - Branch de trabalho onde sera executado e direcionado o resultado da execução do pipeline
  * Repositório de ORIGEM - Deve ser um repositorio existente (para extração) ou deve existir a pasta em repos/<nome_do_repos>/main.tf para permitir a execução do terraform
  * Repositório de DESTINO - Irá direcionar a execução da extração para uma a pasta de DESTINO colocando o nome do repositório de destino na main.tf. Atenção! Irá sobreescrever as configurações existentes na pasta DESTINO. Esta função permite CLONAR configurações repositorios existente com outro nome.
  * Criar script main.tf - Executa extração para criar um novo arquivo de configuração terrafom (main.tf e secrets.tf) baseado no repositorio de origem (que deve existir)
  * Criar script import.tf - Executa extração para criar um novo arquivo de import.tf para carga dos states existentes. Executará no repos de DESTINO caso a informação para clonagem esteja preenchida e o repo de DESTINO exista, executando assim merge de configurações com a ORIGEM.
  * Plan terraform - Executa o INIT e PLAN do terraform para analise do plano
  * Apply terraform - Aplica as configurações terraform
  * Debug? - Aumenta nivel de depuração
3. Verifique o resultado da execução na pasta /repos da sua branch ou em caso de erro nos logs e arquivos anexos do pipeline
4. Caso execução com sucesso abra um pull request para fazer merge com a branch main para manter suas configurações atualizadas
---
![image](https://github.com/user-attachments/assets/1f0d39da-8934-40a7-9710-f666bd51f1b2)
---
### Manipulação direta das configurações
O pipeline extrai os dados do repositorio gerando os arquivos terraform e permite manipular e executar as alterações diretamente a partir do arquivo main.tf
1. Execute a extração do repositorio sem aplicar as alterações (apply)
2. Execute as alterações diretamente no arquivo main.tf e execute apenas o plan para validar suas alterações
3. Execute plan e apply para aplicar suas alterações. Não extraia novamente para nao perder suas alterações
---
![image](https://github.com/user-attachments/assets/4c894f55-2b04-4647-a144-78e61a71ae70)
---   
### Injeção de SECRETS
1. Os pipelines de origem podem ter variaveis secretas (secrets) que são declaradas mas não são clonadas automaticamente pelo pipeline pois a informação não é disponibilizada pela API Github. Para garantir o mapeamento correto as secrets devem ser criadas neste repositorio e mapeadas no pipeline conforme o exemplo abaixo.
  * Todas as secrets são mapeadas através do arquivo secrets.tf, gerado e atualizado pelo pipeline
  * Secrets a nivel de REPOSITORIO são declaradas com o mesmo nome da origem
  * Secrets a nivel de AMBIENTES recebem o {NOME_DO_AMBIENTE}_{NOME_DA_SECRET}
  * As variaveis devem ser declaradas e mapeadas através do pipeline conforme exemplo a seguir
---
![image](https://github.com/user-attachments/assets/a43ff177-0e58-48f2-b9f6-9b9c8edd93f2)
---
![image](https://github.com/user-attachments/assets/6fca6e5c-799b-44b9-bf17-6b1f82dd432d)
---
![image](https://github.com/user-attachments/assets/24463064-dd0e-4c80-a3f4-8c71e1f24480)
---
![image](https://github.com/user-attachments/assets/7731a9e0-6a07-434a-9e91-662363d4396e)
---
