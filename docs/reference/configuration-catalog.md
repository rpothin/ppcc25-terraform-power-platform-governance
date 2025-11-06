# Configuration Catalog

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

**Purpose**: Complete catalog of all available Terraform configurations in this repository  
**Audience**: Developers and administrators looking for specific configurations  
**Format**: Structured reference with examples

---

## Configuration Overview

All configurations are organized in the `configurations/` directory following Azure Verified Module (AVM) naming conventions:

- **`ptn-*`**: Pattern modules (complete implementation patterns)
- **`res-*`**: Resource modules (individual resource types)
- **`utl-*`**: Utility modules (exports, generators, helpers)

---

## Pattern Modules (`ptn-*`)

### ptn-environment-group

**Purpose**: Create a complete environment group with multiple related environments

**Complexity**: ⭐⭐⭐⭐ Advanced  
**Deployment Time**: 30-45 minutes  
**Dependencies**: None

**What it creates**:
- Environment group resource
- Multiple Power Platform environments
- Dataverse databases (optional per environment)
- Application admin assignments (optional)

**Use when**:
- Setting up a new department or project
- Creating dev/test/prod environment sets
- Need related environments managed together

**Example**:
```hcl
# Regional environment group
environment_group_config = {
  display_name = "North America Operations"
  description = "Environment group for NA region"
}

environments = [
  {
    environment = {
      display_name = "NA Production"
      environment_type = "Production"
    }
    dataverse = {
      language_code = 1033
      currency_code = "USD"
    }
  },
  {
    environment = {
      display_name = "NA Development"
      environment_type = "Sandbox"
    }
    dataverse = {
      language_code = 1033
      currency_code = "USD"
    }
  }
]
```

**Documentation**: [configurations/ptn-environment-group/README.md](../../configurations/ptn-environment-group/README.md)

---

### ptn-azure-vnet-extension

**Purpose**: Extend Power Platform environments with Azure Virtual Network integration

**Complexity**: ⭐⭐⭐⭐⭐ Expert  
**Deployment Time**: 45-60 minutes  
**Dependencies**: Existing Azure VNet, Power Platform environment

**What it creates**:
- Virtual network subnet for Power Platform
- Enterprise policy resource
- Enterprise policy link to environment
- Required Azure infrastructure

**Use when**:
- Need private connectivity to Azure resources
- Compliance requires network isolation
- Connecting to on-premises systems via ExpressRoute

**Prerequisites**:
- Azure subscription with VNet
- Power Platform Premium capacity
- Network administrator access

**Example**:
```hcl
vnet_config = {
  resource_group_name = "rg-networking"
  vnet_name = "vnet-powerplatform"
  subnet_name = "snet-powerplatform"
}

environment_id = "00000000-0000-0000-0000-000000000000"
```

**Documentation**: [configurations/ptn-azure-vnet-extension/README.md](../../configurations/ptn-azure-vnet-extension/README.md)

---

## Resource Modules (`res-*`)

### res-dlp-policy

**Purpose**: Create and manage Data Loss Prevention policies

**Complexity**: ⭐⭐ Easy  
**Deployment Time**: 5-10 minutes  
**Dependencies**: None

**What it creates**:
- DLP policy with connector classifications
- Action rules (optional)
- Endpoint filtering (optional)
- Custom connector patterns (optional)

**Use when**:
- Controlling which connectors can be used together
- Preventing data leakage
- Enforcing security standards
- Department-specific policies

**Key Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `display_name` | string | Yes | Policy name (max 50 chars) |
| `description` | string | No | Policy description |
| `default_connectors_classification` | string | No | Default: "Blocked" |
| `environment_type` | string | No | Default: "AllEnvironments" |
| `business_connectors` | list | No | Allowed connectors |
| `non_business_connectors` | list | No | Non-business connectors |
| `blocked_connectors` | list | No | Explicitly blocked |

**Example**:
```hcl
display_name = "Finance DLP Policy"
default_connectors_classification = "Blocked"

business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
    action_rules = [
      { action_id = "DeleteItem_V2", behavior = "Block" }
    ]
  }
]

environment_type = "OnlyEnvironments"
environments = ["<env-id-1>", "<env-id-2>"]
```

**Documentation**: [configurations/res-dlp-policy/README.md](../../configurations/res-dlp-policy/README.md)  
**Tutorial**: [tutorials/02-first-dlp-policy.md](../tutorials/02-first-dlp-policy.md)  
**Guide**: [guides/dlp-policy-management.md](../guides/dlp-policy-management.md)

---

### res-environment

**Purpose**: Create a single Power Platform environment

**Complexity**: ⭐⭐ Easy  
**Deployment Time**: 5-10 minutes (15-20 with Dataverse)  
**Dependencies**: None

**What it creates**:
- Power Platform environment
- Dataverse database (optional)

**Use when**:
- Creating a new environment
- Need fine-grained control over environment settings
- Part of a larger orchestration

**Key Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `display_name` | string | Yes | Environment name |
| `environment_type` | string | Yes | Sandbox, Production, etc. |
| `location` | string | No | Azure region |
| `dataverse.language_code` | number | No | 1033 for English (US) |
| `dataverse.currency_code` | string | No | USD, EUR, etc. |

**Example**:
```hcl
environment = {
  display_name = "Development Environment"
  environment_type = "Sandbox"
  location = "unitedstates"
  description = "Team development workspace"
}

dataverse = {
  language_code = 1033
  currency_code = "USD"
}
```

**Documentation**: [configurations/res-environment/README.md](../../configurations/res-environment/README.md)  
**Tutorial**: [tutorials/03-environment-management.md](../tutorials/03-environment-management.md)

---

### res-environment-settings

**Purpose**: Configure environment-level settings

**Complexity**: ⭐⭐⭐ Medium  
**Deployment Time**: 1-2 minutes  
**Dependencies**: Existing environment

**What it configures**:
- Maker onboarding settings
- Canvas app sharing limits
- Power Platform theme
- Environment-specific features

**Use when**:
- Customizing maker experience
- Enforcing sharing restrictions
- Branding environments
- Configuring governance settings

**Key Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `environment_name` | string | Yes | Target environment name |
| `maker_onboarding_url` | string | No | Welcome URL for makers |
| `limit_sharing_mode` | string | No | Sharing restrictions |
| `max_limit_user_sharing` | number | No | Max users to share with |

**Example**:
```hcl
environment_name = "Production"

maker_onboarding_url = "https://company.com/power-platform-guide"
maker_onboarding_markdown = "# Welcome! Read our guidelines before building."

limit_sharing_mode = "ExcludeSharingToSecurityGroups"
max_limit_user_sharing = 10
```

**Documentation**: [configurations/res-environment-settings/README.md](../../configurations/res-environment-settings/README.md)

---

### res-environment-group

**Purpose**: Create an environment group container

**Complexity**: ⭐ Simple  
**Deployment Time**: 1-2 minutes  
**Dependencies**: None

**What it creates**:
- Environment group resource

**Use when**:
- Grouping related environments
- Organizing by department or project
- Need logical container for environments

**Key Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `display_name` | string | Yes | Group name |
| `description` | string | No | Group description |

**Example**:
```hcl
environment_group_config = {
  display_name = "Finance Department"
  description = "All finance-related environments"
}
```

**Documentation**: [configurations/res-environment-group/README.md](../../configurations/res-environment-group/README.md)

---

### res-environment-application-admin

**Purpose**: Grant application admin access to environments

**Complexity**: ⭐⭐ Easy  
**Deployment Time**: 1-2 minutes  
**Dependencies**: Existing environment, Azure AD application

**What it creates**:
- Application user in environment
- System Administrator role assignment

**Use when**:
- Granting service principals access to environments
- Automation scenarios
- CI/CD pipelines

**Key Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `environment_id` | string | Yes | Target environment ID |
| `application_id` | string | Yes | Azure AD app ID |

**Example**:
```hcl
environment_id = "00000000-0000-0000-0000-000000000000"
application_id = "11111111-1111-1111-1111-111111111111"
```

**Documentation**: [configurations/res-environment-application-admin/README.md](../../configurations/res-environment-application-admin/README.md)

---

### res-enterprise-policy

**Purpose**: Create Azure enterprise policy for network integration

**Complexity**: ⭐⭐⭐⭐ Advanced  
**Deployment Time**: 5-10 minutes  
**Dependencies**: Azure subscription, VNet

**What it creates**:
- Enterprise policy resource in Azure
- Network configuration

**Use when**:
- Setting up VNet integration
- Part of `ptn-azure-vnet-extension` pattern
- Need advanced network policies

**Documentation**: [configurations/res-enterprise-policy/README.md](../../configurations/res-enterprise-policy/README.md)

---

### res-enterprise-policy-link

**Purpose**: Link enterprise policy to Power Platform environment

**Complexity**: ⭐⭐⭐ Medium  
**Deployment Time**: 2-3 minutes  
**Dependencies**: Enterprise policy, Power Platform environment

**What it creates**:
- Link between Azure policy and environment

**Use when**:
- Connecting environment to VNet
- Part of network integration setup

**Documentation**: [configurations/res-enterprise-policy-link/README.md](../../configurations/res-enterprise-policy-link/README.md)

---

## Utility Modules (`utl-*`)

### utl-export-connectors

**Purpose**: Export all available Power Platform connectors

**Complexity**: ⭐ Simple  
**Deployment Time**: 1-2 minutes  
**Dependencies**: None

**What it outputs**:
- JSON file with all connectors
- Connector IDs, names, and metadata
- API endpoints

**Use when**:
- Building DLP policies
- Need current connector IDs
- Auditing available connectors

**Outputs**:
- `connectors`: Complete list of all connectors
- `connector_count`: Total number of connectors
- `connector_summary`: Summary statistics

**Example Output**:
```json
{
  "connectors": [
    {
      "id": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
      "name": "SharePoint",
      "type": "Microsoft"
    }
  ],
  "connector_count": 450
}
```

**Documentation**: [configurations/utl-export-connectors/README.md](../../configurations/utl-export-connectors/README.md)

---

### utl-export-dlp-policies

**Purpose**: Export all existing DLP policies

**Complexity**: ⭐ Simple  
**Deployment Time**: 2-3 minutes  
**Dependencies**: None

**What it outputs**:
- JSON file with all DLP policies
- Complete policy configurations
- Connector classifications

**Use when**:
- Migrating from ClickOps to IaC
- Backing up current policies
- Auditing governance state

**Outputs**:
- `dlp_policies`: Complete policy definitions
- `policy_count`: Total number of policies
- `policy_summary`: Summary by type

**Example Output**:
```json
{
  "dlp_policies": [
    {
      "displayName": "Finance Policy",
      "defaultConnectorsClassification": "Blocked",
      "businessDataGroup": [...]
    }
  ]
}
```

**Documentation**: [configurations/utl-export-dlp-policies/README.md](../../configurations/utl-export-dlp-policies/README.md)

---

### utl-generate-dlp-tfvars

**Purpose**: Generate Terraform tfvars from exported DLP policy

**Complexity**: ⭐⭐ Easy  
**Deployment Time**: 1-2 minutes  
**Dependencies**: Exported DLP policy JSON

**What it generates**:
- Ready-to-use tfvars file
- Complete DLP policy configuration
- Formatted for `res-dlp-policy`

**Use when**:
- Onboarding existing policies to Terraform
- Quickly creating similar policies
- Migration from manual to IaC

**Key Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source_policy_name` | string | Yes | Policy name from export |
| `output_file_name` | string | Yes | Generated file name |

**Example**:
```hcl
source_policy_name = "Finance Data Protection"
output_file_name = "finance-dlp-generated.tfvars"
```

**Documentation**: [configurations/utl-generate-dlp-tfvars/README.md](../../configurations/utl-generate-dlp-tfvars/README.md)  
**Guide**: [guides/dlp-policy-management.md#onboarding-existing-dlp-policies](../guides/dlp-policy-management.md#onboarding-existing-dlp-policies)

---

## Configuration Selection Guide

### By Use Case

| Use Case | Configuration | Complexity |
|----------|--------------|------------|
| Create single environment | `res-environment` | ⭐⭐ |
| Create multiple related environments | `ptn-environment-group` | ⭐⭐⭐⭐ |
| Create DLP policy | `res-dlp-policy` | ⭐⭐ |
| Configure environment settings | `res-environment-settings` | ⭐⭐⭐ |
| Connect to Azure VNet | `ptn-azure-vnet-extension` | ⭐⭐⭐⭐⭐ |
| Export current connectors | `utl-export-connectors` | ⭐ |
| Export current DLP policies | `utl-export-dlp-policies` | ⭐ |
| Migrate existing DLP policy | `utl-generate-dlp-tfvars` | ⭐⭐ |

### By Deployment Time

| Time | Configurations |
|------|----------------|
| < 5 minutes | `utl-export-connectors`, `utl-export-dlp-policies`, `utl-generate-dlp-tfvars`, `res-environment-group` |
| 5-15 minutes | `res-dlp-policy`, `res-environment` (no Dataverse), `res-environment-settings` |
| 15-30 minutes | `res-environment` (with Dataverse) |
| 30-60 minutes | `ptn-environment-group`, `ptn-azure-vnet-extension` |

### By Complexity

| Level | Configurations |
|-------|----------------|
| ⭐ Simple | `utl-*` utilities, `res-environment-group` |
| ⭐⭐ Easy | `res-dlp-policy`, `res-environment`, `res-environment-application-admin` |
| ⭐⭐⭐ Medium | `res-environment-settings`, `res-enterprise-policy-link` |
| ⭐⭐⭐⭐ Advanced | `ptn-environment-group`, `res-enterprise-policy` |
| ⭐⭐⭐⭐⭐ Expert | `ptn-azure-vnet-extension` |

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│ PPCC25 Configuration Quick Reference                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ CREATE DLP POLICY                                           │
│ ├─ Configuration: res-dlp-policy                           │
│ ├─ Vars file: your-policy.tfvars                          │
│ └─ Time: ~10 minutes                                       │
│                                                             │
│ CREATE ENVIRONMENT                                          │
│ ├─ Configuration: res-environment                          │
│ ├─ Vars file: your-environment.tfvars                     │
│ └─ Time: ~10 minutes (+ Dataverse: +10 min)              │
│                                                             │
│ EXPORT CONNECTORS                                           │
│ ├─ Configuration: utl-export-connectors                    │
│ ├─ Vars file: (none)                                      │
│ └─ Time: ~2 minutes                                        │
│                                                             │
│ MIGRATE DLP POLICY                                          │
│ ├─ Step 1: utl-export-dlp-policies                        │
│ ├─ Step 2: utl-generate-dlp-tfvars                        │
│ ├─ Step 3: res-dlp-policy (apply generated)              │
│ └─ Time: ~15 minutes total                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## See Also

- **[Module Reference](module-reference.md)** - Detailed module parameters
- **[Common Patterns](common-patterns.md)** - Reusable configuration patterns
- **[Tutorials](../tutorials/)** - Step-by-step learning guides
- **[How-to Guides](../guides/)** - Task-oriented instructions

---

**Last Updated**: 2025-01-06  
**Version**: 1.0.0  
**Contribute**: [Suggest additions](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
