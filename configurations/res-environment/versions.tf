terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8" # Centralized standard - all modules must match
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  # Azure backend with OIDC for secure, keyless authentication
  backend "azurerm" {
    use_oidc = true
  }
}

provider "powerplatform" {
  use_oidc = true # Enhanced security over client secrets (baseline: security by design)
}