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

terraform {
  required_version = ">= 1.5.0"
  # TODO: Temporarily commented out for hello world test - uncomment for DLP functionality
  # required_providers {
  #   powerplatform = {
  #     source  = "microsoft/power-platform"
  #     version = "~> 3.8"
  #   }
  # }

  backend "azurerm" {
    use_oidc = true
  }
}

# TODO: Temporarily commented out for hello world test - uncomment for DLP functionality
# provider "powerplatform" {
#   use_oidc = true
# }

# TODO: Temporarily commented out for hello world test - uncomment for DLP functionality
# Data Loss Prevention Policies - Main focus of this configuration
# data "powerplatform_data_loss_prevention_policies" "current" {}

# Hello World test values - TODO: Remove after testing
locals {
  test_message = "Hello, World!"
  test_number  = 42
  test_list    = ["item1", "item2", "item3"]
  test_map = {
    environment = "test"
    purpose     = "integration-testing"
  }
}

# Variable for testing - TODO: Remove after testing
variable "test_input" {
  description = "Test input variable"
  type        = string
  default     = "default_value"
}
