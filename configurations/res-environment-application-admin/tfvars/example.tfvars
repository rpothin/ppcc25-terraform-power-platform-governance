# example.tfvars
# Example configuration for Power Platform Environment Application Admin assignment
#
# This file demonstrates how to configure application admin permissions for a
# Power Platform environment using Terraform. Copy this file and update the
# values to match your specific environment and application requirements.
#
# Usage:
#   terraform plan -var-file="example.tfvars"
#   terraform apply -var-file="example.tfvars"

# =============================================================================
# Core Configuration - Required Variables
# =============================================================================

# Target Power Platform environment for admin permission assignment
# Replace with your actual environment GUID from Power Platform Admin Center
environment_id = "12345678-1234-1234-1234-123456789012"

# Azure AD application that will receive System Administrator permissions
# Replace with your actual Azure AD application (client) ID
application_id = "87654321-4321-4321-4321-210987654321"

# =============================================================================
# Configuration Notes
# =============================================================================

# 1. Environment ID Discovery:
#    - Power Platform Admin Center → Environments → Select environment → Settings → Details
#    - PowerShell: Get-AdminPowerAppEnvironment | Select-Object EnvironmentName, EnvironmentId
#    - Azure CLI: az rest --method GET --url "https://api.powerapps.com/providers/Microsoft.PowerApps/environments"

# 2. Application ID Requirements:
#    - Must be registered in Azure AD with Power Platform permissions
#    - Requires "PowerApp Service Admin" or equivalent API permissions
#    - Service principal must exist and be properly configured

# 3. Security Considerations:
#    - System Administrator role provides full environment access
#    - Lifecycle protection prevents accidental deletion
#    - Consider using separate service principals for different environments

# 4. Common Use Cases:
#    - Terraform service principal automation
#    - CI/CD pipeline environment management
#    - Application integration requiring admin privileges
#    - Automated deployment and configuration management