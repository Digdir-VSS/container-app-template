# Github template for CRUD application in Azure Container Apps

## Environmental variables and secrets

This project uses environment variables to configure application settings (such as database URLs, API keys, or runtime options) without hardcoding sensitive values in the code. Environment variables enable secure and flexible configuration for both local development and production deployments.

### Local development

For local development, environment variables can be stored in a `.env` file in the project root. This file is automatically loaded when running the application locally.

⚠️ **Do not commit your `.env` file to Git nor Docker**  
Ensure `.env` is listed in `.gitignore` and `.dockerignore` to prevent leaking sensitive values to the repository.


### Deployment configuration

When deploying using GitHub Actions and Azure Container Apps, environment variables and secrets must be stored securely. There are three recommended storage locations:

| Location | Type | Purpose |
|----------|------|----------|
| **GitHub Actions environment variables** | Non-sensitive | Deployment configuration values (e.g. `RESOURCE_GROUP`, `CONTAINER_APP_NAME`) |
| **GitHub Actions secrets** | Sensitive | Used by pipeline to authenticate (e.g. `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`) |
| **Azure Container App secrets** | Sensitive (runtime) | Application secrets at runtime (e.g. database passwords, API tokens) |

## Usage

```bash
git clone https://github.com/Digdir-VSS/container-app-template.git
```

### Set up infrastructure

This project uses **Terraform** to provision the Azure infrastructure required to run the application in **Azure Container Apps**. Using infrastructure as code ensures consistent, repeatable deployments across environments.

The Terraform configuration is located inside the `infra/` folder and includes:

- Azure Resource Group
- Azure Container Registry (ACR)
- Azure Log Analytics Workspace
- Azure Container Apps Environment
- Two Azure Container Apps (for `dev` and `prod`)
- Required role assignments and networking settings

#### File structure

| File | Description |
|------|-------------|
| `main.tf` | Main Terraform configuration defining Azure resources |
| `variables.tf` | Input variables such as resource names and locations |

Before deployment, you should update `variables.tf` with naming conventions and Azure settings appropriate for your environment.

#### Deploy infrastructure

Before deployment, you should update `variables.tf` with naming conventions and Azure settings appropriate for your environment. 
Moreover, make sure you are logged in Azure and have an Azure subscription. 

Navigate into the infra/ folder and initialize Terraform:

```bash
cd infra
terraform init
```
Review the planned changes:

```bash
terraform plan
```
Apply the configuration to create the Azure resources:

```bash
terraform apply
```
When prompted, type yes to confirm deployment.

Clean up resources (optional)

If you want to remove all provisioned Azure resources:


```bash
terraform destroy
```

#### Set Container App Secrets

After the Azure Container Apps infrastructure is deployed, you must configure **secrets** so the application can run securely. Secrets are used to store sensitive configuration values such as database passwords, API tokens, and connection strings.

Secrets must be added to the **Azure Container App** before the container is deployed and started.

> ⚠️ **Important:** Set secrets **AFTER** running a default container for the first time to avoid startup failures due to missing configuration.

