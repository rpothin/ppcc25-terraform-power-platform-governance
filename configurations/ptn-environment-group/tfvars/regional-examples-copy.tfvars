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

# ==========================================================================
# EXAMPLE 2: ASIA-PACIFIC DEPLOYMENT
# ==========================================================================

# Asia-Pacific regional workspace
# workspace_template = "enterprise"
# name = "APACOperations"
# description = "Asia-Pacific operations workspace for regional business processes"
# location = "asia"

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
location           = "unitedstates"

# State-aware duplicate detection control
# Set to true for existing managed environments to allow updates
assume_existing_environments_are_managed = true