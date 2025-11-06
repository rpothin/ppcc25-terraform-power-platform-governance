# Module Reference

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

**Purpose**: Consolidated reference for all utility and resource modules  
**Audience**: Developers needing detailed parameter information  
**Format**: Technical specifications and examples

---

## Utility Modules

Utility modules perform operations like data export, reporting, and configuration generation. They don't create Power Platform resources but support governance and migration workflows.

### utl-export-dlp-policies

**Purpose**: Export all Data Loss Prevention (DLP) policies in the tenant for reporting, compliance, and migration scenarios.

**Inputs**: None required

**Outputs**:

| Output | Type | Description |
|--------|------|-------------|
| `dlp_policies` | list(object) | Complete DLP policy inventory |
| `policy_count` | number | Total number of policies |
| `dlp_policies_json` | string | JSON string of all policies |

**Example Output**:
```json
{
  "dlp_policies": [
    {
      "displayName": "Finance DLP",
      "defaultConnectorsClassification": "Blocked",
      "environmentType": "OnlyEnvironments",
      "environments": ["env-id-1", "env-id-2"],
      "businessDataGroup": [...],
      "nonBusinessDataGroup": [...],
      "blockedGroup": [...]
    }
  ],
  "policy_count": 5
}
```

**Use Cases**:
- Inventory current governance state
- Backup before making changes
- Migration from ClickOps to IaC
- Compliance reporting
- Audit documentation

**Related Modules**: 
- [utl-generate-dlp-tfvars](#utl-generate-dlp-tfvars)
- [res-dlp-policy](../guides/dlp-policy-management.md)

**Documentation**: [configurations/utl-export-dlp-policies/README.md](../../configurations/utl-export-dlp-policies/README.md)

---

### utl-export-connectors

**Purpose**: Export all Power Platform connectors and their classifications for governance and DLP policy planning.

**Inputs**:

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `timeout` | string | No | "30m" | Operation timeout |

**Outputs**:

| Output | Type | Description |
|--------|------|-------------|
| `connectors` | list(object) | Complete connector inventory |
| `connector_count` | number | Total number of connectors |
| `connectors_by_tier` | object | Connectors grouped by tier |
| `connectors_json` | string | JSON string of all connectors |

**Example Output**:
```json
{
  "connectors": [
    {
      "id": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
      "name": "shared_sharepointonline",
      "type": "Microsoft.PowerApps/apis",
      "properties": {
        "displayName": "SharePoint",
        "iconUri": "https://...",
        "tier": "Standard"
      }
    }
  ],
  "connector_count": 450,
  "connectors_by_tier": {
    "Standard": 350,
    "Premium": 100
  }
}
```

**Use Cases**:
- Identify available connectors for DLP policies
- Get correct connector IDs (case-sensitive!)
- Audit connector usage across tenant
- Plan governance strategies
- Generate connector inventories

**Related Modules**: 
- [res-dlp-policy](../guides/dlp-policy-management.md)
- [utl-export-dlp-policies](#utl-export-dlp-policies)

**Documentation**: [configurations/utl-export-connectors/README.md](../../configurations/utl-export-connectors/README.md)

---

### utl-generate-dlp-tfvars

**Purpose**: Generate Terraform tfvars files from exported DLP policies to accelerate IaC adoption.

**Inputs**:

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `source_policy_name` | string | Yes | - | Name of policy to convert |
| `output_file_name` | string | Yes | - | Generated tfvars file name |
| `source_policies_json` | string | No | (from export) | JSON from utl-export-dlp-policies |

**Outputs**:

| Output | Type | Description |
|--------|------|-------------|
| `generated_tfvars_content` | string | Complete tfvars file content |
| `generated_file_path` | string | Path to generated file |

**Example Usage**:
```hcl
source_policy_name = "Finance Data Protection"
output_file_name = "finance-dlp.tfvars"
```

**Generated Output Example**:
```hcl
# Generated from existing DLP policy: Finance Data Protection
# Generated on: 2025-01-06
# Review and customize before applying

display_name = "Finance Data Protection"
description = "Generated from existing policy - review before use"

default_connectors_classification = "Blocked"

business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
  }
]

environment_type = "OnlyEnvironments"
environments = [
  "d55dae23-ebcf-e76d-b63d-bece332f560c"
]
```

**Use Cases**:
- Accelerate migration from ClickOps to IaC
- Create similar policies quickly
- Backup policy configurations as code
- Bootstrap new Terraform configurations

**Related Modules**: 
- [utl-export-dlp-policies](#utl-export-dlp-policies) (prerequisite)
- [res-dlp-policy](../guides/dlp-policy-management.md) (consumes output)

**Documentation**: [configurations/utl-generate-dlp-tfvars/README.md](../../configurations/utl-generate-dlp-tfvars/README.md)

---

## Common Parameters Across Modules

### Standard Metadata

Most resource modules accept these standard parameters:

```hcl
display_name = "Resource Name"        # Human-readable name
description  = "Purpose and context"  # Optional but recommended
```

### Tags (Where Applicable)

```hcl
tags = {
  environment = "Production"
  project     = "Finance Automation"
  managed_by  = "Terraform"
  cost_center = "IT-12345"
}
```

### Provider Configuration

All modules inherit provider configuration from the root module:

```hcl
# Root module sets provider
provider "powerplatform" {
  use_oidc = true
  # Configuration via environment variables:
  # - POWER_PLATFORM_USE_OIDC
  # - POWER_PLATFORM_CLIENT_ID
  # - POWER_PLATFORM_TENANT_ID
}

# Child modules inherit automatically
```

---

## Data Types Reference

### Environment Type

Valid values for `environment_type`:

```hcl
environment_type = "Sandbox"      # Testing and UAT
environment_type = "Production"   # Business-critical workloads
environment_type = "Trial"        # 30-day evaluation
environment_type = "Developer"    # Individual developer workspaces
environment_type = "Default"      # Not recommended
```

### Connector Classification

Valid values for DLP connector classifications:

```hcl
default_connectors_classification = "Business"    # Allow by default
default_connectors_classification = "NonBusiness" # Separate data group
default_connectors_classification = "Blocked"     # Block by default (recommended)
```

### DLP Environment Type

Valid values for DLP policy scope:

```hcl
environment_type = "AllEnvironments"              # Apply to all (default)
environment_type = "OnlyEnvironments"             # Specific environments only
environment_type = "ExceptEnvironments"           # All except specified
environment_type = "SingleEnvironment"            # One environment (legacy)
```

### Language Codes

Common language codes for Dataverse:

```hcl
language_code = 1033  # English (United States)
language_code = 1036  # French (France)
language_code = 1031  # German (Germany)
language_code = 1034  # Spanish (Spain)
language_code = 1040  # Italian (Italy)
language_code = 1041  # Japanese
language_code = 1042  # Korean
language_code = 2052  # Chinese (Simplified)
language_code = 1028  # Chinese (Traditional)
```

### Currency Codes

Common currency codes for Dataverse:

```hcl
currency_code = "USD"  # US Dollar
currency_code = "EUR"  # Euro
currency_code = "GBP"  # British Pound
currency_code = "JPY"  # Japanese Yen
currency_code = "AUD"  # Australian Dollar
currency_code = "CAD"  # Canadian Dollar
currency_code = "CHF"  # Swiss Franc
```

### Azure Regions

Common region codes:

```hcl
location = "unitedstates"     # United States
location = "europe"           # Europe
location = "asia"             # Asia
location = "australia"        # Australia
location = "canada"           # Canada
location = "unitedkingdom"    # United Kingdom
location = "japan"            # Japan
location = "india"            # India
```

---

## Validation Rules

### Display Name

```hcl
# Maximum length: 50 characters
# Pattern: Alphanumeric, spaces, hyphens, underscores
# Required: Yes (for most resources)

display_name = "Valid Name 123-test"  # ✅ Valid
display_name = "This name is way too long and will fail validation because it exceeds fifty characters"  # ❌ Too long
```

### Environment ID

```hcl
# Format: GUID (UUID)
# Pattern: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

environment_id = "d55dae23-ebcf-e76d-b63d-bece332f560c"  # ✅ Valid
environment_id = "my-environment"  # ❌ Invalid format
```

### Connector ID

```hcl
# Format: /providers/Microsoft.PowerApps/apis/{connector-name}
# Case-sensitive!

id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"  # ✅ Valid
id = "shared_sharepointonline"  # ❌ Missing provider prefix
id = "/providers/Microsoft.PowerApps/apis/SharePointOnline"  # ❌ Wrong case
```

---

## Error Handling

### Common Validation Errors

**Display Name Too Long**:
```
Error: Invalid value for variable "display_name"
Value must be 50 characters or less
```
Solution: Shorten the display name

**Invalid Environment Type**:
```
Error: Invalid value for variable "environment_type"
Must be one of: Sandbox, Production, Trial, Developer
```
Solution: Use exact case-sensitive value

**Invalid GUID Format**:
```
Error: Invalid environment_id format
Must be a valid GUID
```
Solution: Get correct GUID from Admin Center

### Resource Conflicts

**Resource Already Exists**:
```
Error: A resource with the ID "..." already exists
```
Solutions:
1. Import existing resource: `terraform import`
2. Use different name
3. Delete existing resource first

---

## Best Practices

### Naming Conventions

```hcl
# Good: Descriptive, includes context
display_name = "Finance Prod - DLP Policy"
display_name = "NA Region - Dev Environment"

# Avoid: Generic, unclear purpose
display_name = "Policy 1"
display_name = "Test"
```

### Documentation

```hcl
# Always include description
description = <<-EOT
  Finance department DLP policy
  Blocks all connectors except approved finance systems
  Last updated: 2025-01-06
  Owner: finance-team@company.com
EOT
```

### Variable Organization

```hcl
# Group related variables
# Use comments to explain WHY

# Core Configuration
display_name = "Finance DLP"
description = "..."

# Security Settings - WHY: Prevent data leakage
default_connectors_classification = "Blocked"

# Environment Scope - WHY: Production only
environment_type = "OnlyEnvironments"
environments = ["prod-env-id"]
```

---

## Version Compatibility

### Required Versions

```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.8"
    }
  }
}
```

### Provider Version History

| Version | Release Date | Key Features |
|---------|-------------|--------------|
| 3.8.x | 2024-11 | DLP enhancements, enterprise policies |
| 3.7.x | 2024-09 | Environment groups, improved OIDC |
| 3.6.x | 2024-07 | Initial OIDC support |

---

## Performance Considerations

### Module Call Performance

| Operation | Typical Duration | Notes |
|-----------|-----------------|-------|
| Export connectors | 1-2 minutes | ~450 connectors |
| Export DLP policies | 2-3 minutes | Depends on policy count |
| Generate tfvars | < 1 minute | File generation only |
| Create DLP policy | 30-60 seconds | API latency |
| Create environment | 5-10 minutes | Platform provisioning |
| Create environment with Dataverse | 10-20 minutes | Database initialization |

### Optimization Tips

```hcl
# Reduce parallelism if experiencing throttling
terraform apply -parallelism=5

# Use targeted applies for specific resources
terraform apply -target=module.specific_resource

# Enable debug logging only when troubleshooting
# export TF_LOG=DEBUG
```

---

## See Also

- **[Configuration Catalog](configuration-catalog.md)** - Complete configuration overview
- **[Common Patterns](common-patterns.md)** - Reusable patterns and examples
- **[Troubleshooting Guide](../guides/troubleshooting.md)** - Common issues and solutions
- **[Terraform Provider Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)**

---

**Last Updated**: 2025-01-06  
**Version**: 1.0.0  
**Feedback**: [Improve this reference](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
