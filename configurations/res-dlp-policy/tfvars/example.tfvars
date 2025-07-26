# Example tfvars for res-dlp-policy
#
# This file provides a sample configuration for deploying a DLP policy using the res-dlp-policy module.
# All values are based on the official provider documentation and can be customized for your environment.

# Display name for the DLP policy
# (string, required)
display_name = "Block All Policy"

# Default classification for connectors ("General", "Confidential", "Blocked")
# (string, required)
default_connectors_classification = "Blocked"

# Environment type for the policy ("AllEnvironments", "ExceptEnvironments", "OnlyEnvironments")
# (string, required)
environment_type = "AllEnvironments"

# List of environment IDs to which the policy is applied (optional, empty for all environments)
# (list(string), optional)
environments = []

# Business connectors (set of objects, required)
business_connectors = [
  {
    id                           = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
    action_rules = [
      {
        action_id = "DeleteItem_V2"
        behavior  = "Block"
      },
      {
        action_id = "ExecutePassThroughNativeQuery_V2"
        behavior  = "Block"
      }
    ]
    endpoint_rules = [
      {
        behavior = "Allow"
        endpoint = "contoso.com"
        order    = 1
      },
      {
        behavior = "Deny"
        endpoint = "*"
        order    = 2
      }
    ]
  },
  {
    id                           = "/providers/Microsoft.PowerApps/apis/shared_approvals"
    default_action_rule_behavior = ""
    action_rules                 = []
    endpoint_rules               = []
  },
  {
    id                           = "/providers/Microsoft.PowerApps/apis/shared_cloudappsecurity"
    default_action_rule_behavior = ""
    action_rules                 = []
    endpoint_rules               = []
  }
]

# Non-business connectors (set of objects, required)
non_business_connectors = [
  # Example: Add connectors as needed
]

# Blocked connectors (set of objects, required)
blocked_connectors = [
  # Example: Add connectors as needed
]

# Custom connectors patterns (set of objects, required)
custom_connectors_patterns = [
  {
    order            = 1
    host_url_pattern = "https://*.contoso.com"
    data_group       = "Blocked"
  },
  {
    order            = 2
    host_url_pattern = "*"
    data_group       = "Ignore"
  }
]
