# Provider and version constraints for res-environment module
# Child module - provider configuration handled by parent

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}