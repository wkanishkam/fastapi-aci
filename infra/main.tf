terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "acr_suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "FastAPI-ACI"
  }
}

resource "azurerm_container_registry" "main" {
  name                = var.acr_name != "" ? var.acr_name : "${replace(var.prefix, "-", "")}acr${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = "FastAPI-ACI"
  }
}

resource "azurerm_user_assigned_identity" "aci" {
  name                = "${var.prefix}-aci-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aci.principal_id
}

resource "azurerm_container_group" "main" {
  name                = "${var.prefix}-container-group"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-fastapi-aci"
  os_type             = "Linux"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aci.id]
  }

  image_registry_credential {
    server                    = azurerm_container_registry.main.login_server
    user_assigned_identity_id = azurerm_user_assigned_identity.aci.id
  }

  container {
    name   = "fastapi-app"
    image  = "python:3.11-slim"
    cpu    = "0.5"
    memory = "1.5"
    
    commands = ["python", "-c", "import http.server; import socketserver; PORT = 8000; Handler = http.server.SimpleHTTPRequestHandler; socketserver.TCPServer.allow_reuse_address = True; with socketserver.TCPServer(('', PORT), Handler) as httpd: print(f'Server running at port {PORT}'); httpd.serve_forever()"]

    ports {
      port     = 8000
      protocol = "TCP"
    }

    environment_variables = {
      "ENV" = var.environment
    }
  }

  lifecycle {
    ignore_changes = [
      container[0].image,
      container[0].commands
    ]
  }

  tags = {
    Environment = var.environment
    Project     = "FastAPI-ACI"
  }

  depends_on = [azurerm_role_assignment.aci_acr_pull]
}