# Provider and version constraints for res-dlp-policy module
#
# This module is designed to be called from parent configurations.
# Provider configuration should be handled by the calling module.
#
# Key Requirements:
# - Provider Version: Using centralized standard ~> 3.8 for microsoft/power-platform
# - No Provider Block: Child modules receive provider configuration from parent
# - No Backend Block: State management handled by calling configuration

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}
