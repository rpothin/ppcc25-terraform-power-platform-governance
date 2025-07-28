# Example tfvars for res-dlp-policy
#
# This file provides sample configurations for all supported usage patterns.
#

# The default (uncommented) block is the recommended full auto-classification pattern, using security-first defaults.
# Other patterns are provided as commented-out alternatives below.

# -----------------------------------------------------------------------------
# 1. Full Auto-Classification (Recommended, Security-First)
#    - Only business_connectors (as list of IDs) and custom_connectors_patterns provided
#    - non_business_connectors and blocked_connectors will be auto-classified
#    - Uses security-first defaults: environment_type = "OnlyEnvironments", custom_connectors_patterns blocks all by default
display_name                      = "Block All Policy"
default_connectors_classification = "Blocked"          # Security-first default
environment_type                  = "OnlyEnvironments" # Security-first default
environments                      = []
business_connectors = [
  "/providers/Microsoft.PowerApps/apis/shared_sql",
  "/providers/Microsoft.PowerApps/apis/shared_approvals"
]
custom_connectors_patterns = [
  {
    order            = 1
    host_url_pattern = "*"
    data_group       = "Blocked" # Security-first: block all custom connectors by default
  }
]

# -----------------------------------------------------------------------------
# 2. Partial Auto-Classification (Override Example)
#    - Provide business_connectors and one of non_business_connectors or blocked_connectors
#    - The other will be auto-classified
#    - Example below intentionally overrides the security-first custom_connectors_patterns
# -----------------------------------------------------------------------------
# display_name = "Block All Policy"
# default_connectors_classification = "Blocked"
# environment_type = "OnlyEnvironments" # Security-first default
# environments = []
# business_connectors = [
#   "/providers/Microsoft.PowerApps/apis/shared_sql"
# ]
# non_business_connectors = [
#   {
#     id                           = "/providers/Microsoft.PowerApps/apis/shared_twitter"
#     default_action_rule_behavior = "Allow"
#     action_rules                 = []
#     endpoint_rules               = []
#   }
# ]
# custom_connectors_patterns = [
#   {
#     order            = 1
#     host_url_pattern = "https://*.contoso.com"
#     data_group       = "Blocked"
#   },
#   {
#     order            = 2
#     host_url_pattern = "*"
#     data_group       = "Ignore" # Override: allow all except specific pattern
#   }
# ]

# -----------------------------------------------------------------------------
# 3. Full Manual (Override Example)
#    - Provide all connector classifications explicitly
#    - Example below intentionally overrides the security-first custom_connectors_patterns
# -----------------------------------------------------------------------------
# display_name = "Block All Policy"
# default_connectors_classification = "Blocked"
# environment_type = "OnlyEnvironments" # Security-first default
# environments = []
# business_connectors = [
#   "/providers/Microsoft.PowerApps/apis/shared_sql"
# ]
# non_business_connectors = [
#   {
#     id                           = "/providers/Microsoft.PowerApps/apis/shared_twitter"
#     default_action_rule_behavior = "Allow"
#     action_rules                 = []
#     endpoint_rules               = []
#   }
# ]
# blocked_connectors = [
#   {
#     id                           = "/providers/Microsoft.PowerApps/apis/shared_dropbox"
#     default_action_rule_behavior = "Block"
#     action_rules                 = []
#     endpoint_rules               = []
#   }
# ]
# custom_connectors_patterns = [
#   {
#     order            = 1
#     host_url_pattern = "https://*.contoso.com"
#     data_group       = "Blocked"
#   },
#   {
#     order            = 2
#     host_url_pattern = "*"
#     data_group       = "Ignore" # Override: allow all except specific pattern
#   }
# ]

# -----------------------------------------------------------------------------
# 4. Traditional (business_connectors null, others provided, Override Example)
#    - business_connectors is null, both non_business_connectors and blocked_connectors must be provided
#    - Example below intentionally overrides the security-first custom_connectors_patterns
# -----------------------------------------------------------------------------
# display_name = "Block All Policy"
# default_connectors_classification = "Blocked"
# environment_type = "OnlyEnvironments" # Security-first default
# environments = []
# non_business_connectors = [
#   {
#     id                           = "/providers/Microsoft.PowerApps/apis/shared_twitter"
#     default_action_rule_behavior = "Allow"
#     action_rules                 = []
#     endpoint_rules               = []
#   }
# ]
# blocked_connectors = [
#   {
#     id                           = "/providers/Microsoft.PowerApps/apis/shared_dropbox"
#     default_action_rule_behavior = "Block"
#     action_rules                 = []
#     endpoint_rules               = []
#   }
# ]
# custom_connectors_patterns = [
#   {
#     order            = 1
#     host_url_pattern = "https://*.contoso.com"
#     data_group       = "Blocked"
#   },
#   {
#     order            = 2
#     host_url_pattern = "*"
#     data_group       = "Ignore" # Override: allow all except specific pattern
#   }
# ]