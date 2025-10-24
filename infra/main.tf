terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.52.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_workspace
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "containerappenv" {
  name                       = var.container_environment
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

}

resource "azurerm_container_registry" "container-reg" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}


# -------------------------------
# DEV Container App
# -------------------------------
resource "azurerm_container_app" "container_dev" {
  name                         = var.dev_aca_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.containerappenv.id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }
  

  registry {
    server   = azurerm_container_registry.container-reg.login_server
    identity = "System"
  }

  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "projectportfoliocontainerapp"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}

# -------------------------------
# PROD Container App
# -------------------------------
resource "azurerm_container_app" "container_prod" {
  name                         = var.aca_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.containerappenv.id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  registry {
    server   = azurerm_container_registry.container-reg.login_server
    identity = "System"
  }

  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "projectportfoliocontainerapp"
      image  = "mcr.microsoft.com/k8se/quickstart:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      
    }
  }
}

# -------------------------------
# ACR Pull Permissions
# -------------------------------
resource "azurerm_role_assignment" "acr_pull_dev" {
  scope                = azurerm_container_registry.container-reg.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.projectportfolio_dev.identity[0].principal_id
}

resource "azurerm_role_assignment" "acr_pull_prod" {
  scope                = azurerm_container_registry.container-reg.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.projectportfolio_prod.identity[0].principal_id
}