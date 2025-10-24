variable "location" { default = "norwayeast" }
variable "resource_group_name" { default = "" }
variable "aca_name" { default = "" }
variable "dev_aca_name" { default = "" }
variable "acr_name" { default = "" }
variable "container_image" { default = "mcr.microsoft.com/k8se/quickstart:latest" }
variable "container_environment" { default = "Environment" }
variable "log_analytics_workspace" { default = "" }