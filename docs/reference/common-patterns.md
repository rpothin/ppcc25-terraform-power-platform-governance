# Common Patterns

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

**Purpose**: Reusable configuration patterns for common scenarios  
**Audience**: Developers looking for proven solutions  
**Format**: Copy-paste ready examples with explanations

---

## DLP Policy Patterns

### Pattern: Maximum Security Baseline

**Use When**: Starting fresh governance or high-security requirements

```hcl
# Maximum security: Block everything, allow only explicitly approved
display_name = "Baseline Security - Block All"
description = "Default-deny policy applied to all environments"

# Block by default
default_connectors_classification = "Blocked"

# Explicitly allow only essential Microsoft 365 services
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_office365users"
    default_action_rule_behavior = "Allow"
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_teams"
    default_action_rule_behavior = "Allow"
  }
]

# Apply globally
environment_type = "AllEnvironments"
```

**Why**: Default-deny is the most secure approach. Users can only use connectors you explicitly approve.

---

### Pattern: SQL Server with Restricted Operations

**Use When**: Need database access but want to prevent destructive operations

```hcl
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
    
    # WHY: Allow reads, block dangerous operations
    action_rules = [
      { action_id = "DeleteItem_V2", behavior = "Block" },
      { action_id = "ExecutePassThroughNativeQuery_V2", behavior = "Block" },
      { action_id = "ExecuteProcedure_V2", behavior = "Block" }
    ]
    
    # WHY: Only allow approved database servers
    endpoint_rules = [
      { endpoint = "approved-db.database.windows.net", behavior = "Allow", order = 1 },
      { endpoint = "finance-db.database.windows.net", behavior = "Allow", order = 2 },
      { endpoint = "*", behavior = "Block", order = 3 }
    ]
  }
]
```

**Why**: Gives developers database access while preventing accidental data loss and limiting to approved servers.

---

### Pattern: SharePoint Site Restriction

**Use When**: Allow SharePoint but only specific sites

```hcl
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
    
    # WHY: Restrict to departmental sites only
    endpoint_rules = [
      { endpoint = "company.sharepoint.com/sites/finance", behavior = "Allow", order = 1 },
      { endpoint = "company.sharepoint.com/sites/hr", behavior = "Allow", order = 2 },
      { endpoint = "*", behavior = "Block", order = 3 }
    ]
  }
]
```

**Why**: Prevents users from connecting to unauthorized SharePoint sites that may contain sensitive data.

---

### Pattern: Development vs Production Policies

**Use When**: Need different rules for different environment types

**Development Policy (Permissive)**:
```hcl
display_name = "Development - Permissive"
description = "Flexible policy for development environments"

# Allow most connectors in dev
default_connectors_classification = "Business"

# Only block the truly dangerous ones
blocked_connectors = [
  { id = "/providers/Microsoft.PowerApps/apis/shared_sendgrid" },
  { id = "/providers/Microsoft.PowerApps/apis/shared_twiliosms" }
]

# Apply to dev environments only
environment_type = "OnlyEnvironments"
environments = ["dev-env-id-1", "dev-env-id-2"]
```

**Production Policy (Restrictive)**:
```hcl
display_name = "Production - Strict"
description = "Locked-down policy for production environments"

# Block by default
default_connectors_classification = "Blocked"

# Minimal approved list
business_connectors = [
  { id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline" },
  { id = "/providers/Microsoft.PowerApps/apis/shared_sql" },
  { id = "/providers/Microsoft.PowerApps/apis/shared_commondataservice" }
]

# Production only
environment_type = "OnlyEnvironments"
environments = ["prod-env-id"]
```

**Why**: Enables innovation in dev while maintaining security in production.

---

### Pattern: Block All Custom Connectors

**Use When**: Want to prevent unapproved external API connections

```hcl
# Block all custom connectors by default
custom_connectors_patterns = [
  { order = 1, host_url_pattern = "*", data_group = "Blocked" }
]
```

**Allow Only Internal APIs**:
```hcl
custom_connectors_patterns = [
  { order = 1, host_url_pattern = "*.internal.company.com", data_group = "Business" },
  { order = 2, host_url_pattern = "api.company.com", data_group = "Business" },
  { order = 3, host_url_pattern = "*", data_group = "Blocked" }
]
```

**Why**: Prevents data exfiltration through unapproved custom connectors.

---

## Environment Patterns

### Pattern: Standard Environment with Dataverse

**Use When**: Creating a typical business environment

```hcl
environment = {
  display_name = "Sales Production"
  environment_type = "Production"
  location = "unitedstates"
  description = "Sales team production environment with Dataverse"
}

dataverse = {
  language_code = 1033  # English (US)
  currency_code = "USD"
  
  # Optional: Restrict access to security group
  # security_group_id = "00000000-0000-0000-0000-000000000000"
}
```

**Why**: Provides all necessary components for model-driven apps and advanced scenarios.

---

### Pattern: Lightweight Sandbox (No Dataverse)

**Use When**: Quick testing environment without database overhead

```hcl
environment = {
  display_name = "Quick Test Sandbox"
  environment_type = "Sandbox"
  description = "Lightweight testing environment without Dataverse"
}

# Omit dataverse block entirely for faster creation
```

**Why**: Creates environment in ~5 minutes instead of ~15 minutes. Good for canvas app testing.

---

### Pattern: Regional Environment Group

**Use When**: Need multiple environments in the same region

```hcl
environment_group_config = {
  display_name = "EMEA Operations"
  description = "European, Middle East, and Africa region environments"
}

environments = [
  {
    environment = {
      display_name = "EMEA Production"
      environment_type = "Production"
      location = "europe"
    }
    dataverse = {
      language_code = 1033
      currency_code = "EUR"
    }
  },
  {
    environment = {
      display_name = "EMEA UAT"
      environment_type = "Sandbox"
      location = "europe"
    }
    dataverse = {
      language_code = 1033
      currency_code = "EUR"
    }
  },
  {
    environment = {
      display_name = "EMEA Development"
      environment_type = "Sandbox"
      location = "europe"
    }
    dataverse = {
      language_code = 1033
      currency_code = "EUR"
    }
  }
]
```

**Why**: Groups related environments together for easier management and consistent configuration.

---

### Pattern: Multi-Language Environment

**Use When**: Supporting different languages across environments

```hcl
# French environment
environment = {
  display_name = "France Production"
  environment_type = "Production"
  location = "europe"
}

dataverse = {
  language_code = 1036  # French
  currency_code = "EUR"
}
```

```hcl
# German environment
environment = {
  display_name = "Germany Production"
  environment_type = "Production"
  location = "europe"
}

dataverse = {
  language_code = 1031  # German
  currency_code = "EUR"
}
```

**Why**: Each environment can have its own language and currency settings matching regional requirements.

---

## Environment Settings Patterns

### Pattern: Maker Onboarding

**Use When**: Want to provide guidance to new app makers

```hcl
environment_name = "Development"

# WHY: Guide new makers to training resources
maker_onboarding_url = "https://company.com/power-platform/getting-started"

maker_onboarding_markdown = <<-EOT
# Welcome to Power Platform!

Before you start building:
1. Complete [required training](https://company.com/training)
2. Review our [governance guidelines](https://company.com/governance)
3. Join our [Teams channel](https://teams.microsoft.com/...)

Need help? Contact: powerplatform@company.com
EOT
```

**Why**: Ensures all makers see important information when they first access the environment.

---

### Pattern: Restricted Sharing

**Use When**: Need to control how widely apps can be shared

```hcl
environment_name = "Production"

# WHY: Prevent over-sharing of production apps
limit_sharing_mode = "ExcludeSharingToSecurityGroups"
max_limit_user_sharing = 10

# WHY: Only approved security groups can be granted access
# Individual sharing limited to 10 users
```

**Why**: Prevents accidental exposure of sensitive apps to large populations.

---

### Pattern: Branded Environment

**Use When**: Want consistent branding across maker portals

```hcl
environment_name = "Sales Production"

power_platform_theme = {
  logo_url = "https://company.com/assets/logo.png"
  primary_color = "#0078D4"
  header_color = "#FFFFFF"
}

maker_onboarding_markdown = <<-EOT
# Sales Team Environment
This environment is specifically for sales applications and workflows.
EOT
```

**Why**: Provides clear visual indication of which environment makers are working in.

---

## File Organization Patterns

### Pattern: Department-Based Structure

```
configurations/res-dlp-policy/tfvars/
├── finance/
│   ├── prod.tfvars
│   ├── uat.tfvars
│   └── dev.tfvars
├── hr/
│   ├── prod.tfvars
│   └── dev.tfvars
├── sales/
│   ├── prod.tfvars
│   └── dev.tfvars
└── it/
    └── global-baseline.tfvars
```

**Why**: Clear ownership and easier to find department-specific policies.

---

### Pattern: Environment-Based Structure

```
configurations/res-dlp-policy/tfvars/
├── production/
│   ├── finance-prod.tfvars
│   ├── hr-prod.tfvars
│   └── sales-prod.tfvars
├── uat/
│   ├── finance-uat.tfvars
│   └── sales-uat.tfvars
└── development/
    ├── dev-permissive.tfvars
    └── dev-isolated.tfvars
```

**Why**: Easy to see what's deployed to each environment type.

---

### Pattern: Purpose-Based Structure

```
configurations/res-dlp-policy/tfvars/
├── global/
│   └── baseline-security.tfvars
├── compliance/
│   ├── gdpr.tfvars
│   ├── hipaa.tfvars
│   └── sox.tfvars
├── projects/
│   ├── project-alpha.tfvars
│   └── project-beta.tfvars
└── testing/
    └── test-policy.tfvars
```

**Why**: Organized by policy purpose and compliance requirements.

---

## Naming Convention Patterns

### Pattern: Descriptive Naming

```hcl
# Good: Clear purpose and scope
display_name = "Finance Prod - Data Protection"
display_name = "HR - Confidential Data Access"
display_name = "Sales EMEA - CRM Integration"

# Avoid: Generic or unclear
display_name = "Policy 1"
display_name = "Test"
display_name = "New Policy"
```

### Pattern: Versioned Naming

```hcl
# For iterative testing
display_name = "Finance DLP - v1.0"
display_name = "Finance DLP - v1.1"
display_name = "Finance DLP - v2.0 - Major Update"
```

### Pattern: Hierarchical Naming

```hcl
# Shows inheritance and precedence
display_name = "001-Global-Baseline"
display_name = "002-Regional-EMEA"
display_name = "003-Department-Finance"
display_name = "004-Environment-Prod"
```

---

## Variable Patterns

### Pattern: Reusable Variables

```hcl
# In a locals.tf or shared file
locals {
  # Standard Microsoft 365 connectors
  standard_m365_connectors = [
    { id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline" },
    { id = "/providers/Microsoft.PowerApps/apis/shared_office365" },
    { id = "/providers/Microsoft.PowerApps/apis/shared_teams" },
    { id = "/providers/Microsoft.PowerApps/apis/shared_office365users" }
  ]
  
  # Standard data connectors
  standard_data_connectors = [
    { id = "/providers/Microsoft.PowerApps/apis/shared_sql" },
    { id = "/providers/Microsoft.PowerApps/apis/shared_azureblob" },
    { id = "/providers/Microsoft.PowerApps/apis/shared_commondataservice" }
  ]
}

# Use in your tfvars
business_connectors = concat(
  local.standard_m365_connectors,
  local.standard_data_connectors
)
```

**Why**: Define once, reuse everywhere. Ensures consistency.

---

### Pattern: Environment-Specific Variables

```hcl
# variables.tf
variable "environment" {
  type = string
}

# Conditional logic based on environment
locals {
  is_production = var.environment == "production"
  
  max_sharing_limit = local.is_production ? 5 : 50
  
  allowed_connectors = local.is_production ? [
    # Minimal list for production
  ] : [
    # Broader list for non-production
  ]
}
```

**Why**: Single configuration that adapts based on environment.

---

## Testing Patterns

### Pattern: Canary Deployment

```hcl
# Step 1: Create with different name
display_name = "Finance DLP - Canary"

# Step 2: Apply to single test environment
environment_type = "OnlyEnvironments"
environments = ["test-env-id"]

# Step 3: Verify, then expand
# Change to production environments after validation
```

**Why**: Test changes in isolation before broad rollout.

---

### Pattern: Blue-Green Deployment

```hcl
# Blue (current production)
display_name = "Finance DLP - Blue"
environments = ["prod-env-1", "prod-env-2"]

# Green (new version)
display_name = "Finance DLP - Green"
environments = ["prod-env-3"]  # One test prod environment

# After validation, swap environments
# Update Blue to remove prod-env-3
# Update Green to include all prod environments
# Delete Blue
```

**Why**: Zero-downtime policy updates with easy rollback.

---

## Error Handling Patterns

### Pattern: Graceful Degradation

```hcl
# Prefer optional variables with sensible defaults
variable "custom_connectors_patterns" {
  type = list(object({
    order            = number
    host_url_pattern = string
    data_group       = string
  }))
  default = [
    # Safe default: Block all custom connectors
    { order = 1, host_url_pattern = "*", data_group = "Blocked" }
  ]
}
```

**Why**: Configuration works even if user doesn't provide values.

---

### Pattern: Validation Before Apply

```hcl
# In variables.tf
variable "display_name" {
  type = string
  
  validation {
    condition     = length(var.display_name) <= 50
    error_message = "Display name must be 50 characters or less"
  }
  
  validation {
    condition     = length(var.display_name) > 0
    error_message = "Display name cannot be empty"
  }
}
```

**Why**: Catch errors early before API calls fail.

---

## See Also

- **[Configuration Catalog](configuration-catalog.md)** - Complete list of configurations
- **[Module Reference](module-reference.md)** - Detailed parameter documentation
- **[Tutorials](../tutorials/)** - Step-by-step learning
- **[DLP Policy Management](../guides/dlp-policy-management.md)** - Complete DLP guide

---

**Last Updated**: 2025-01-06  
**Version**: 1.0.0  
**Contribute**: [Share your patterns](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
