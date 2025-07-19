# Power Platform Data Loss Prevention Policies Export Configuration
# This configuration demonstrates how to export current DLP policies for migration to IaC
# Use this as a reference for creating single-purpose data source configurations

terraform {
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
  
  backend "azurerm" {
    use_oidc = true
  }
}

provider "powerplatform" {
  use_oidc = true
}

# Data Loss Prevention Policies - Main focus of this configuration
data "powerplatform_data_loss_prevention_policies" "current" {}
