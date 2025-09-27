# Live Demo Configuration for PPCC25 Presentation
#
# This configuration is optimized for live demonstration during the PPCC25 session:
# "Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"
#
# Purpose: Real-time deployment and governance demonstration with audience interaction

# ==========================================================================
# PRESENTATION-OPTIMIZED EXAMPLES
# ==========================================================================

# Example scenarios that work well for live demonstrations:
# 1. Quick environment provisioning during presentation
# 2. Real-time governance policy application
# 3. Multi-environment scaling demonstration
# 4. Audience-interactive configuration changes

# ==========================================================================
# SECURITY GROUP CONFIGURATION FOR LIVE DEMO
# ==========================================================================

# ⚠️  LIVE DEMO CONSIDERATION: security_group_id controls actual user access
#
# During live demonstration:
# - This group controls which users can access environments created during the demo
# - Consider using a demo-specific security group for isolation
# - Ensure the group has appropriate members for post-demo cleanup
# - Document group membership for security audit trail
#
# Demo-specific considerations:
# 1. Use dedicated demo security group if available
# 2. Limit membership to demo participants only
# 3. Plan for post-demo environment cleanup
# 4. Consider temporary group membership for demo duration
#
# Production note: In real scenarios, this would be department/team-specific groups

# ==========================================================================
# LIVE DEMO BEST PRACTICES
# ==========================================================================

# During live presentation:
# 1. Pre-validate configuration syntax before session
# 2. Test deployment in demo-prep environment first
# 3. Have rollback plan ready for any issues
# 4. Keep resource names short and readable for audience
# 5. Use consistent naming for easy identification during demo

# ==========================================================================
# SUPPORTED REGIONS FOR DEMOS
# ==========================================================================

# Recommended regions for live demonstrations:
# - canada          (Fast deployment, good latency for North America)
# - unitedstates    (Familiar to most audiences)
# - europe          (Good for EU audiences)
#
# Consider audience location when selecting region for optimal demo experience

# ==========================================================================
# LIVE DEMONSTRATION CONFIGURATION
# ==========================================================================

# Optimized for live PPCC25 session demonstration
workspace_template = "basic"
name               = "LiveDemoWorkspace"
description        = "Live demonstration workspace for PPCC25 session - real-time governance and IaC showcase"
location           = "canada"
security_group_id  = "6a199811-5433-4076-81e8-1ca7ad8ffb67"

# ==========================================================================
# LIVE DEMO DEPLOYMENT NOTES
# ==========================================================================

# Pre-presentation checklist:
# 1. Validate tfvars syntax: terraform validate -var-file="tfvars/live-demo.tfvars"
# 2. Test plan generation: terraform plan -var-file="tfvars/live-demo.tfvars"
# 3. Verify Azure authentication is working
# 4. Confirm Power Platform permissions are available
# 5. Test paired Azure VNet extension configuration

# During presentation commands:
# terraform init (if not already done)
# terraform plan -var-file="tfvars/live-demo.tfvars"
# terraform apply -var-file="tfvars/live-demo.tfvars"

# Post-demo cleanup:
# terraform destroy -var-file="tfvars/live-demo.tfvars"