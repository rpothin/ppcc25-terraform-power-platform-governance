# Azure VNet Extension Live Demo Configuration
#
# This file pairs with ptn-environment-group/tfvars/live-demo.tfvars
# for live demonstration during PPCC25 session presentation.
# Optimized for real-time deployment and audience interaction.

# ==========================================================================
# LIVE DEMO NETWORK STRATEGY
# ==========================================================================

# Network ranges specifically chosen to:
# 1. Avoid overlap with demo-prep configuration (10.200.x.x/10.216.x.x ranges)
# 2. Use familiar, easy-to-remember ranges for live presentation
# 3. Support multiple environments for scaling demonstrations
# 4. Enable real-time network expansion during demos

# ==========================================================================
# MINIMAL CONFIGURATION - For Quick Live Demo Start
# ==========================================================================

# Uncomment this section for rapid deployment during presentation:
# paired_tfvars_file = "live-demo"
# production_subscription_id = "7d237ead-2d0d-4dda-b0d7-2a3ecf235a1c"
# non_production_subscription_id = "7d237ead-2d0d-4dda-b0d7-2a3ecf235a1c"
# network_configuration = {
#   primary = {
#     location = "Canada Central"
#     vnet_address_space_base = "10.100.0.0/12"
#   }
#   failover = {
#     location = "Canada East"  
#     vnet_address_space_base = "10.116.0.0/12"
#   }
#   subnet_allocation = {
#     power_platform_subnet_size = 24
#     private_endpoint_subnet_size = 24
#     power_platform_offset = 1
#     private_endpoint_offset = 2
#   }
# }

# ==========================================================================
# DETAILED LIVE DEMO CONFIGURATION
# ==========================================================================

# ==========================================================================
# PAIRED CONFIGURATION - Must Match Environment Group
# ==========================================================================

# WHY: Ensures state consistency between paired patterns during live demo
# LIVE DEMO IMPACT: Allows real-time resource coordination and dependency tracking
# AUDIENCE BENEFIT: Demonstrates proper IaC state management practices
paired_tfvars_file = "live-demo"

# ==========================================================================
# SUBSCRIPTION CONFIGURATION - Live Demo Environment  
# ==========================================================================

# Production subscription for live demo environments
# Note: Using same subscription for simplicity during presentation
production_subscription_id = "7d237ead-2d0d-4dda-b0d7-2a3ecf235a1c"

# Non-production subscription for live demo environments  
# Note: Using same subscription for simplicity during presentation
non_production_subscription_id = "7d237ead-2d0d-4dda-b0d7-2a3ecf235a1c"

# ==========================================================================
# LIVE DEMO NETWORK CONFIGURATION - Non-Overlapping IP Ranges
# ==========================================================================

# ⚠️  CRITICAL: IP ranges chosen to avoid conflict with demo-prep configuration
# 
# IP Range Allocation Strategy:
# - demo-prep.tfvars:  10.200.0.0/12 (10.200.x.x - 10.215.x.x) + 10.216.0.0/12 (10.216.x.x - 10.231.x.x)
# - live-demo.tfvars:  10.100.0.0/12 (10.100.x.x - 10.115.x.x) + 10.116.0.0/12 (10.116.x.x - 10.131.x.x)
#
# Benefits for live demonstration:
# - Clear separation allows both configurations to coexist
# - Easy to remember ranges (10.100.x.x vs 10.200.x.x)
# - No network conflicts during simultaneous deployments
# - Audience can see distinct resource naming patterns

network_configuration = {
  primary = {
    location = "Canada Central"
    # WHY: Large address space for live demo environment scaling
    # LIVE DEMO BENEFIT: Can demonstrate adding environments in real-time
    # AUDIENCE IMPACT: Shows dynamic IP allocation without manual calculation
    vnet_address_space_base = "10.100.0.0/12" # 10.100.0.0 - 10.115.255.255

    # WHY: Automatic per-environment IP allocation during demo
    # LIVE DEMO BENEFIT: Audience sees infrastructure expand dynamically
    # PRESENTATION IMPACT: No manual IP planning required during live demo
  }
  failover = {
    location = "Canada East"
    # WHY: Separate IP range for regional redundancy demonstration
    # LIVE DEMO BENEFIT: Can show cross-region deployment in real-time
    # AUDIENCE IMPACT: Demonstrates disaster recovery and regional resilience
    vnet_address_space_base = "10.116.0.0/12" # 10.116.0.0 - 10.131.255.255
  }

  # WHY: Consistent subnet layout across all environments
  # LIVE DEMO BENEFIT: Predictable networking for audience understanding
  # PRESENTATION IMPACT: Clean, professional resource organization
  subnet_allocation = {
    power_platform_subnet_size   = 24 # /24 = 256 IPs per environment
    private_endpoint_subnet_size = 24 # /24 = 256 IPs per environment
    power_platform_offset        = 1  # .1.0/24 within each /16
    private_endpoint_offset      = 2  # .2.0/24 within each /16
  }
}

# ==========================================================================
# PRIVATE DNS ZONES - Live Demo Azure Service Integration
# ==========================================================================

# WHY: Demonstrate enterprise-grade private connectivity during live session
# LIVE DEMO BENEFIT: Show real Azure service integration without public exposure
# AUDIENCE IMPACT: Illustrates zero-trust networking principles
private_dns_zones = [
  "privatelink.vaultcore.azure.net",   # Azure Key Vault
  "privatelink.blob.core.windows.net", # Azure Storage Blob
  "privatelink.file.core.windows.net", # Azure Storage Files
  "privatelink.documents.azure.com",   # Azure Cosmos DB
  "privatelink.database.windows.net"   # Azure SQL Database
]

# ==========================================================================
# GOVERNANCE TAGGING - Live Demo Resource Identification
# ==========================================================================

# WHY: Clear resource identification during and after live demo
# LIVE DEMO BENEFIT: Easy cleanup and cost tracking post-presentation
# AUDIENCE IMPACT: Shows proper resource governance and cost management
tags = {
  Environment = "Live-Demo"
  Project     = "PPCC25"
  Pattern     = "ptn-azure-vnet-extension"
  Purpose     = "Power Platform VNet Integration Live Demonstration"
}

# ==========================================================================
# LIVE DEMO IP ALLOCATION EXAMPLES - What Audience Will See
# ==========================================================================

# WHY: Help audience understand dynamic IP allocation during presentation
# LIVE DEMO BENEFIT: Clear examples for Q&A and troubleshooting
# PRESENTATION IMPACT: Professional documentation demonstrates best practices

# Live Demo Example with 3 environments (dev, test, prod):
# Environment 0 (dev):   Primary: 10.100.0.0/16, Failover: 10.116.0.0/16
#   - Power Platform:     Primary: 10.100.1.0/24, Failover: 10.116.1.0/24  
#   - Private Endpoints:  Primary: 10.100.2.0/24, Failover: 10.116.2.0/24
# Environment 1 (test):  Primary: 10.101.0.0/16, Failover: 10.117.0.0/16
#   - Power Platform:     Primary: 10.101.1.0/24, Failover: 10.117.1.0/24
#   - Private Endpoints:  Primary: 10.101.2.0/24, Failover: 10.117.2.0/24
# Environment 2 (prod):  Primary: 10.102.0.0/16, Failover: 10.118.0.0/16
#   - Power Platform:     Primary: 10.102.1.0/24, Failover: 10.118.1.0/24
#   - Private Endpoints:  Primary: 10.102.2.0/24, Failover: 10.118.2.0/24

# Live Demo Example with 4 environments (dev, test, uat, prod):
# Environment 3 (uat):   Primary: 10.103.0.0/16, Failover: 10.119.0.0/16

# Live Demo Example with 2 environments (non-prod, prod):
# Environment 0 (non-prod): Primary: 10.100.0.0/16, Failover: 10.116.0.0/16
# Environment 1 (prod):     Primary: 10.101.0.0/16, Failover: 10.117.0.0/16

# ==========================================================================
# LIVE DEMO COMPARISON WITH DEMO-PREP
# ==========================================================================

# Network Range Comparison for Audience Understanding:
#
# Configuration    | Primary Range      | Failover Range     | Purpose
# -----------------|-------------------|-------------------|------------------
# demo-prep.tfvars | 10.200.0.0/12     | 10.216.0.0/12     | Pre-presentation setup
# live-demo.tfvars | 10.100.0.0/12     | 10.116.0.0/12     | Live presentation demo
#
# Benefits of separation:
# - Both configurations can be deployed simultaneously
# - Clear resource identification (10.100.x.x = live, 10.200.x.x = prep)
# - No network conflicts or resource naming collisions
# - Independent lifecycle management

# ==========================================================================
# LIVE PRESENTATION DEPLOYMENT WORKFLOW
# ==========================================================================

# Pre-session preparation:
# 1. Validate configuration: terraform validate -var-file="tfvars/live-demo.tfvars"
# 2. Test deployment: terraform plan -var-file="tfvars/live-demo.tfvars"
# 3. Prepare demo script with command examples
# 4. Test connectivity and permissions

# During live session:
# 1. Show configuration files to audience
# 2. Execute: terraform plan -var-file="tfvars/live-demo.tfvars"
# 3. Explain the plan output to audience
# 4. Execute: terraform apply -var-file="tfvars/live-demo.tfvars"
# 5. Demonstrate resource creation in real-time
# 6. Show Azure portal resources being created

# Post-session cleanup:
# terraform destroy -var-file="tfvars/live-demo.tfvars"
# Verify all resources removed to prevent ongoing costs

# ==========================================================================
# AUDIENCE Q&A PREPARATION
# ==========================================================================

# Common questions and answers for live demo:
#
# Q: "Why separate IP ranges for demo-prep and live-demo?"
# A: Allows both to coexist, prevents conflicts, enables different demo scenarios
#
# Q: "Can these be deployed to different regions?"
# A: Yes, change location variables - IP ranges remain non-overlapping
#
# Q: "What happens if deployment fails during demo?"
# A: Terraform state tracks partial deployments, can resume or rollback safely
#
# Q: "How do you handle secrets during live demo?"
# A: Using OIDC authentication, no secrets stored in configuration files

# ==========================================================================
# DYNAMIC REMOTE STATE FOR LIVE DEMO
# ==========================================================================

# Benefits during presentation:
# - No hardcoded state storage - cleaner for audience
# - State inheritance from execution context
# - Consistent with production best practices
# - Simplified configuration for audience understanding