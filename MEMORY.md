# Project Memory

## 1. Context and Objectives
* **Technologies**: github, bash, json, yq, jq, awk.
* ** Objectives**: This application is an "Infrastructure as Code" tool for GitHub governance. It enables a company to take the security and operational configurations of a "template" repository and replicate them at scale across new repositories, ensuring that all of them adhere to the same standards for branch protection, secrets, and permissions without the need for manual configuration of each one.

## 2. Architectural Decisions (ADRs)
* **[2026-10-04]**: Memory file to support IA created

## 3. Current Development Status
* **[2026-10-04]**: Initial IA environment setup

## 4. Known Issues and Technical Debt
* **[2026-10-04]**: The "branch protection" block in the `run_terraform.yml` pipeline file does not include all the attributes required for repository creation via Terraform.
