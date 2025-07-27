
# Example tfvars for res-dlp-policy
#
# This file provides sample configurations for all supported usage patterns.
#
# The default (uncommented) block is the recommended full auto-classification pattern.
# Other patterns are provided as commented-out alternatives below.

# -----------------------------------------------------------------------------
# 1. Full Auto-Classification (Recommended)
#    - Only business_connectors (as list of IDs) and custom_connectors_patterns provided
#    - non_business_connectors and blocked_connectors will be auto-classified
# -----------------------------------------------------------------------------
display_name = "Block All Policy"
default_connectors_classification = "Blocked"
environment_type = "AllEnvironments"
environments = []
business_connectors = [
	"/providers/Microsoft.PowerApps/apis/shared_sql",
	"/providers/Microsoft.PowerApps/apis/shared_approvals"
]
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

# -----------------------------------------------------------------------------
# 2. Partial Auto-Classification
#    - Provide business_connectors and one of non_business_connectors or blocked_connectors
#    - The other will be auto-classified
# -----------------------------------------------------------------------------
# display_name = "Block All Policy"
# default_connectors_classification = "Blocked"
# environment_type = "AllEnvironments"
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
#   }
# ]

# -----------------------------------------------------------------------------
# 3. Full Manual
#    - Provide all connector classifications explicitly
# -----------------------------------------------------------------------------
# display_name = "Block All Policy"
# default_connectors_classification = "Blocked"
# environment_type = "AllEnvironments"
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
#   }
# ]

# -----------------------------------------------------------------------------
# 4. Traditional (business_connectors null, others provided)
#    - business_connectors is null, both non_business_connectors and blocked_connectors must be provided
# -----------------------------------------------------------------------------
# display_name = "Block All Policy"
# default_connectors_classification = "Blocked"
# environment_type = "AllEnvironments"
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
#   }
# ]
