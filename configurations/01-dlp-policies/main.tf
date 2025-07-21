# DLP Policies Export Configuration
#
# This configuration demonstrates how to export current Data Loss Prevention policies 
# from Power Platform for migration planning. It serves as a reference for creating 
# single-purpose Terraform configurations that target specific data sources while 
# following AVM best practices.
#
# Key Features:
# - AVM-Inspired Structure: Follows AVM patterns where technically feasible
# - Anti-Corruption Layer: Outputs discrete attributes instead of complete resource objects
# - Security-First: Sensitive data properly marked and segregated
# - Migration Ready: Structured output for analysis and migration planning

# Test

terraform {
  required_version = ">= 1.5.0"
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
