# Provider and version constraints for res-enterprise-policy module
#
# Child module - provider configuration inherited from parent module.
# No backend or provider blocks per AVM specification TFNFR27.
#
# Baseline Requirements:
# - Terraform: >= 1.5.0 (consistent with repository baseline)
# - Provider: azure/azapi ~> 2.6 (for Microsoft.PowerPlatform/enterprisePolicies)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.6"
    }
  }
}