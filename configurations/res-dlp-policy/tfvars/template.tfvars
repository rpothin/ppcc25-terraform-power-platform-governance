# -----------------------------------------------------------------------------
# Power Platform DLP Policy - Terraform tfvars Template
# -----------------------------------------------------------------------------
# This template is for creating new DLP policies using IaC. It follows security-first,
# AVM-compliant, and demonstration-quality principles. Only essential variables are
# included; others use secure defaults from the module. See README in this folder for guidance.
#
# Usage:
# 1. Copy this file and rename as needed (e.g., my-policy.tfvars).
# 2. Fill in required values below. Leave commented examples for reference.
# 3. Run `terraform plan -var-file="path/to/your.tfvars"` to validate.
# -----------------------------------------------------------------------------

# REQUIRED: Human-readable name for the DLP policy (max 50 chars, must be unique)
display_name = "Template DLP Policy"

# OPTIONAL: Classification for connectors. Choose one: "General", "Confidential", "Blocked"
# If omitted, defaults to "Blocked" (secure default)
# default_connectors_classification = "Blocked"

# OPTIONAL: Environment handling. Choose one: "AllEnvironments", "ExceptEnvironments", "OnlyEnvironments"
# If omitted, defaults to "OnlyEnvironments" (secure default)
# environment_type = "OnlyEnvironments"

# OPTIONAL: List of environment IDs to apply the policy to. Leave empty for all environments.
# environments = ["env-id-1", "env-id-2"]

# OPTIONAL: Business connectors configuration. Use output from `utl-export-connectors` for onboarding.
# Example:
# business_connectors = [
#   {
#     id = "/providers/Microsoft.PowerApps/apis/shared_sql"
#     default_action_rule_behavior = "Allow"
#     action_rules = [
#       { action_id = "DeleteItem_V2", behavior = "Block" }
#     ]
#     endpoint_rules = [
#       { endpoint = "contoso.com", behavior = "Allow", order = 1 }
#     ]
#   }
# ]

# OPTIONAL: Non-business connectors configuration. Usually left empty for new policies.
# non_business_connectors = []

# OPTIONAL: Blocked connectors configuration. Add connectors to block explicitly.
# blocked_connectors = []

# OPTIONAL: Custom connector patterns. By default, all custom connectors are blocked for security.
# To allow specific patterns, override as shown below.
# custom_connectors_patterns = [
#   { order = 1, host_url_pattern = "https://*.contoso.com", data_group = "Business" },
#   { order = 2, host_url_pattern = "*", data_group = "Blocked" }
# ]
