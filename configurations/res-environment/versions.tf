# Provider and version constraints for res-environment module
#
# Child module - provider configuration inherited from parent module.
# No backend or provider blocks per AVM specification TFNFR27.
#
# Baseline Requirements:
# - Terraform: >= 1.5.0 (consistent with repository baseline)
# - Provider: microsoft/power-platform ~> 3.8 (centralized version standard)
# - Provider: hashicorp/null ~> 3.0 (for lifecycle management)

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