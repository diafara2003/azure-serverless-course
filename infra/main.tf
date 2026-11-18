resource "azurerm_resource_group" "name" {
  name = "${var.project_name}-${var.environment}-rg"
  location = "${var.location}"
}