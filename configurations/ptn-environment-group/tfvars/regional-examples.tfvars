# Regional Variations Examples
#
# This file demonstrates how the same template can be used across
# different Power Platform regions while maintaining consistent governance.

# ==========================================================================
# EXAMPLE 1: EUROPEAN DEPLOYMENT
# ==========================================================================

# European customer data workspace
# workspace_template = "basic"
# name = "EuropeCustomers"
# description = "European customer data management workspace with GDPR compliance"
# location = "europe"
# security_group_id = "12345678-1234-1234-1234-123456789abc"  # EU-Security-Group from Entra ID

# ==========================================================================
# EXAMPLE 2: ASIA-PACIFIC DEPLOYMENT
# ==========================================================================

# Asia-Pacific regional workspace
# workspace_template = "enterprise"
# name = "APACOperations"
# description = "Asia-Pacific operations workspace for regional business processes"
# location = "asia"
# security_group_id = "87654321-4321-4321-4321-abcdef123456"  # APAC-PowerPlatform-Users from Entra ID

# ==========================================================================
# SECURITY GROUP CONFIGURATION
# ==========================================================================

# ⚠️  CRITICAL: security_group_id must be an Entra ID Security Group ID, NOT a service principal ID
#
# What it controls:
# - Which users can access the Power Platform environments
# - User membership in all environments created by this workspace
# - Dataverse security boundaries and governance
#
# How to get the correct ID:
# 1. Open Azure Portal
# 2. Go to Microsoft Entra ID → Groups
# 3. Find your security group (e.g., "PowerPlatform-Users", "Finance-Team")
# 4. Click on the group → Properties
# 5. Copy the "Object ID" (this is your security_group_id)
#
# Example security groups by use case:
# - "PowerPlatform-Developers"     → Development environments access
# - "Finance-PowerPlatform-Users"  → Finance department environments
# - "Regional-EMEA-Users"          → European region environments
#
# Common mistake: Using a Service Principal ID instead of Security Group ID
# - Service Principal = Application/automation identity
# - Security Group = User group for access control

# ==========================================================================
# EXAMPLE 3: MULTI-REGION CONSIDERATIONS
# ==========================================================================

# When deploying across multiple regions:
# 1. Use consistent naming conventions across regions
# 2. Consider data residency and compliance requirements
# 3. Plan for cross-region governance policies
# 4. Account for regional-specific Power Platform capabilities

# ==========================================================================
# SUPPORTED REGIONS
# ==========================================================================

# All templates support these Power Platform regions:
# - unitedstates    (North America)
# - europe          (European Union)
# - asia            (Asia-Pacific)
# - australia       (Australia/New Zealand)
# - unitedkingdom   (United Kingdom)
# - india           (India)
# - canada          (Canada)
# - southamerica    (South America)
# - france          (France)
# - unitedarabemirates (UAE)
# - southafrica     (South Africa)
# - germany         (Germany)
# - switzerland     (Switzerland)
# - norway          (Norway)
# - korea           (South Korea)
# - japan           (Japan)

# ==========================================================================
# ACTIVE CONFIGURATION (Uncomment to use)
# ==========================================================================

# Default example for demonstration
workspace_template = "basic"
name               = "DemoWorkspace"
description        = "Demonstration workspace for PPCC25 session"
location           = "canada"
security_group_id  = "6a199811-5433-4076-81e8-1ca7ad8ffb67"