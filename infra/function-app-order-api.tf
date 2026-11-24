resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    "course" = "serverless"
  }
}


resource "azurerm_application_insights" "app1_insights" {
  name                = "${var.environment}-${var.project_name}-app1-ai"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "other"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  tags = {
    "course" = "serverless"
    "func"   = "${var.project_name}-api-${var.environment}"
  }

}


# Flex Consumption guarda el paquete de código desplegado en un contenedor de blobs.
resource "azurerm_storage_container" "order_api_deploy" {
  name                  = "order-api-deploy"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_function_app_flex_consumption" "order-api-func" {
  name                = "${var.project_name}-api-${var.environment}-func01"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.my_plan.id

  # Dónde vive el código desplegado y cómo se autentica la app contra ese storage
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.main.primary_blob_endpoint}${azurerm_storage_container.order_api_deploy.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.main.primary_access_key

  # En Flex el runtime va aquí, no en FUNCTIONS_WORKER_RUNTIME
  runtime_name    = "python"
  runtime_version = "3.11"

  maximum_instance_count = 40
  instance_memory_in_mb  = 2048

  # Necesario para desplegar con publish profile (usuario/password del SCM).
  # En Flex viene desactivado por defecto.
  webdeploy_publish_basic_authentication_enabled = true

  site_config {
    application_insights_connection_string = azurerm_application_insights.app1_insights.connection_string
  }

  tags = {
    "course" = "serverless"
    "func"   = "${var.project_name}-api-${var.environment}"
  }
}