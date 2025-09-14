# Enterprise Policy Provider Requirements Configuration
#
# This file defines provider requirements for the enterprise policy resource module
# following AVM child module patterns for maximum compatibility.
#
# Child Module Design:
# - No Provider Blocks: Inherits configuration from parent (AVM TFNFR27)
# - No Backend Blocks: State management handled by parent module
# - Meta-Argument Compatible: Supports for_each, count, depends_on
# - Under 20 Lines: Meets AVM child module size requirements
#
# Provider Requirements:
# - azapi ~> 2.2: For Microsoft.PowerPlatform resource management
# - Terraform >= 1.5.0: For advanced validation and lifecycle features
#
# WHY: Child module pattern enables orchestration in pattern modules
# This design allows ptn-azure-vnet-extension to use this module with meta-arguments

# Child module versions.tf - MUST be under 20 lines
# No provider or backend blocks (inherit from parent)
# WHY: This format ensures compatibility with meta-arguments (for_each, count, depends_on)
# and aligns with AVM specification TFNFR27
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.6"
    }
  }
}