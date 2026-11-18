variable "location" {
  description = "azure region"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "projet name"
  type        = string
  default     = "order-system"
}

variable "environment" {
  description = "environment name"
  type        = string
  default     = "dev"
}