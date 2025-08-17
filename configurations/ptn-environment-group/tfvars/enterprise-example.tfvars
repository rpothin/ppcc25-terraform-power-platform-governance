# Enterprise Template Example - Four-tier Development Lifecycle
#
# This example demonstrates the "enterprise" workspace template which creates
# a comprehensive four-tier development lifecycle with Dev, Staging, Test, and Prod.
# Designed for mission-critical applications with strict governance requirements.

# ==========================================================================
# WORKSPACE CONFIGURATION
# ==========================================================================

# Template selection: "enterprise" creates full four-tier lifecycle
workspace_template = "enterprise"

# Workspace name: Used as base for environment names
# Will generate: "CriticalApp - Dev", "CriticalApp - Staging", "CriticalApp - Test", "CriticalApp - Prod"
name = "CriticalApp"

# Workspace description: Explains the business purpose and compliance requirements
description = "Mission-critical application workspace with enterprise-grade governance and compliance controls"

# Power Platform region: All environments will be created in this region
location = "unitedstates"

# ==========================================================================
# EXPECTED RESULTS
# ==========================================================================

# Environment Group: "CriticalApp - Environment Group"
# Environments Created:
#   1. "CriticalApp - Dev" (Sandbox) - Development environment for feature development
#   2. "CriticalApp - Staging" (Sandbox) - Pre-production validation environment
#   3. "CriticalApp - Test" (Sandbox) - Quality assurance and user acceptance testing
#   4. "CriticalApp - Prod" (Production) - Live production environment
#
# Enterprise Benefits:
# - Complete separation of concerns across development lifecycle
# - Staging environment for pre-production validation
# - Comprehensive testing capabilities before production deployment
# - Enhanced governance and compliance alignment
# - Reduced production risk through thorough validation stages

# ==========================================================================
# GOVERNANCE INTEGRATION
# ==========================================================================

# This enterprise template is designed to integrate with:
# - Data Loss Prevention (DLP) policies at the environment group level
# - Environment routing rules for controlled access
# - Advanced monitoring and compliance reporting
# - Automated deployment pipelines with stage gates
# - Enterprise security and access control policies

# ==========================================================================
# USAGE INSTRUCTIONS
# ==========================================================================

# To deploy this example:
# 1. Copy this file to terraform.tfvars in the ptn-environment-group directory
# 2. Update the values to match your requirements
# 3. Run: terraform init && terraform plan && terraform apply
#
# When to use Enterprise Template:
# - Mission-critical business applications
# - Applications with strict compliance requirements
# - Large-scale enterprise deployments
# - Applications requiring comprehensive testing workflows
# - Scenarios with complex governance and security needs