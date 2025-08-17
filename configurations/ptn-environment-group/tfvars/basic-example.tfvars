# Basic Template Example - Three-tier Development Lifecycle
#
# This example demonstrates the "basic" workspace template which creates
# a standard three-tier development lifecycle with Dev, Test, and Prod environments.
# Perfect for typical application development scenarios.

# ==========================================================================
# WORKSPACE CONFIGURATION
# ==========================================================================

# Template selection: "basic" creates Dev, Test, and Prod environments
workspace_template = "basic"

# Workspace name: Used as base for environment names
# Will generate: "CustomerPortal - Dev", "CustomerPortal - Test", "CustomerPortal - Prod"
name = "CustomerPortal"

# Workspace description: Explains the business purpose
description = "Customer portal development workspace for external customer self-service applications"

# Power Platform region: All environments will be created in this region
location = "unitedstates"

# ==========================================================================
# EXPECTED RESULTS
# ==========================================================================

# Environment Group: "CustomerPortal - Environment Group"
# Environments Created:
#   1. "CustomerPortal - Dev" (Sandbox) - Development environment
#   2. "CustomerPortal - Test" (Sandbox) - Testing environment  
#   3. "CustomerPortal - Prod" (Production) - Production environment
#
# All environments will:
# - Be assigned to the environment group automatically
# - Include the monitoring service principal for tenant-level oversight
# - Have Dataverse databases with default USD currency and English language
# - Use auto-generated domain names based on environment names

# ==========================================================================
# USAGE INSTRUCTIONS
# ==========================================================================

# To deploy this example:
# 1. Copy this file to terraform.tfvars in the ptn-environment-group directory
# 2. Update the values to match your requirements
# 3. Run: terraform init && terraform plan && terraform apply
#
# To customize:
# - Change "name" to your project name
# - Update "description" to explain your workspace purpose
# - Modify "location" to your preferred Power Platform region
# - Keep "workspace_template" as "basic" for three-tier lifecycle