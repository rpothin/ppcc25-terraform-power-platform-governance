# Simple Template Example - Two-tier Development Lifecycle
#
# This example demonstrates the "simple" workspace template which creates
# a minimal two-tier development lifecycle with Dev and Prod environments only.
# Ideal for small projects or proof-of-concept scenarios.

# ==========================================================================
# WORKSPACE CONFIGURATION
# ==========================================================================

# Template selection: "simple" creates only Dev and Prod environments
workspace_template = "simple"

# Workspace name: Used as base for environment names
# Will generate: "InternalTools - Dev", "InternalTools - Prod"
name = "InternalTools"

# Workspace description: Explains the business purpose
description = "Internal productivity tools workspace for employee workflow automation"

# Power Platform region: All environments will be created in this region
location = "europe"

# ==========================================================================
# EXPECTED RESULTS
# ==========================================================================

# Environment Group: "InternalTools - Environment Group"
# Environments Created:
#   1. "InternalTools - Dev" (Sandbox) - Development environment
#   2. "InternalTools - Prod" (Production) - Production environment
#
# Benefits of Simple Template:
# - Faster deployment with fewer environments
# - Lower resource consumption and costs
# - Streamlined governance with minimal complexity
# - Perfect for internal tools and quick projects

# ==========================================================================
# USAGE INSTRUCTIONS
# ==========================================================================

# To deploy this example:
# 1. Copy this file to terraform.tfvars in the ptn-environment-group directory
# 2. Update the values to match your requirements
# 3. Run: terraform init && terraform plan && terraform apply
#
# When to use Simple Template:
# - Small internal projects
# - Proof-of-concept scenarios
# - Teams with limited governance requirements
# - Quick prototype development