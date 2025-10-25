# -----------------------------------------------------------------------------
# Power Platform Environment Group Pattern - Terraform tfvars Template
# -----------------------------------------------------------------------------
# This template is for creating environment groups with multiple environments using IaC.
# It follows security-first, AVM-compliant, and demonstration-quality principles.
# Template-driven configuration provides predefined workspace layouts for different use cases.
# See README in this folder for detailed guidance and usage examples.
#
# Usage:
# 1. Copy this file and rename as needed (e.g., my-workspace.tfvars).
# 2. Fill in required values below. Leave commented examples for reference.
# 3. Run `terraform plan -var-file="path/to/your.tfvars"` to validate.
# -----------------------------------------------------------------------------

# REQUIRED: Workspace template defining environment structure
# Choose one: "basic" (3 envs), "simple" (2 envs), "enterprise" (4 envs)
workspace_template = "basic"

# REQUIRED: Base name for the workspace (max 50 chars, combined with environment suffixes)
# This creates: "[name] - Dev", "[name] - Test", "[name] - Prod" (for basic template)
name = "LiveDemoWorkspace"

# REQUIRED: Description of workspace purpose and governance approach (1-200 chars)
description = "Live demonstration workspace for PPCC25 session - real-time governance and IaC showcase"

# REQUIRED: Power Platform geographic region for all environments
# Supported: unitedstates, europe, asia, australia, unitedkingdom, india, canada,
#            southamerica, france, unitedarabemirates, southafrica, germany,
#            switzerland, norway, korea, japan
location = "canada"

# REQUIRED: Entra ID Security Group Object ID (GUID format)
# Controls user access to all environments in this workspace
# ⚠️ IMPORTANT: This must be a Security Group ID, NOT a Service Principal ID
#
# How to get Security Group ID:
# 1. Open Azure Portal → Microsoft Entra ID → Groups
# 2. Find your security group (e.g., "PowerPlatform-Users")
# 3. Click Properties → Copy "Object ID"
#
# Example security groups by use case:
# - "PowerPlatform-Developers"     → Development workspace access
# - "Finance-PowerPlatform-Users"  → Finance department workspace
# - "Regional-EMEA-Users"          → European region workspace
security_group_id = "6a199811-5433-4076-81e8-1ca7ad8ffb67"

# -----------------------------------------------------------------------------
# TEMPLATE DETAILS
# -----------------------------------------------------------------------------
#
# "basic" template creates:
#   - ProjectName - Dev  (Sandbox, full debugging, open access)
#   - ProjectName - Test (Sandbox, moderate security, balanced auditing)
#   - ProjectName - Prod (Production, strict security, comprehensive audit)
#
# "simple" template creates:
#   - ProjectName - Dev  (Sandbox, full debugging, open access)
#   - ProjectName - Prod (Production, strict security, comprehensive audit)
#
# "enterprise" template creates:
#   - ProjectName - Dev     (Sandbox, full debugging, comprehensive settings)
#   - ProjectName - Staging (Sandbox, pre-prod validation, controlled access)
#   - ProjectName - Test    (Sandbox, UAT focused, moderate security)
#   - ProjectName - Prod    (Production, maximum security, full compliance)
#
# All templates include:
# - Automatic environment group creation and assignment
# - Managed environment configuration for enhanced governance
# - Environment-specific settings (audit, security, features, email)
# - Monitoring service principal as application admin on all environments
# -----------------------------------------------------------------------------
