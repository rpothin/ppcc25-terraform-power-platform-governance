# DLP Policy Management Guide

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

**Purpose**: Complete guide to creating, managing, and onboarding Data Loss Prevention policies using Terraform  
**Audience**: Platform administrators ready to implement DLP governance  
**Prerequisites**: [Getting Started Tutorial](../tutorials/01-getting-started.md) completed

---

## Overview

This guide covers everything you need to manage Data Loss Prevention (DLP) policies using Terraform, from creating new policies to onboarding existing ones.

## Quick Start

### Deploy Your First DLP Policy

**Time**: 10 minutes

1. Navigate to the configuration:
   ```bash
   cd configurations/res-dlp-policy/tfvars/
   ```

2. Copy the template:
   ```bash
   cp template.tfvars my-policy.tfvars
   ```

3. Edit your policy (see examples below)

4. Deploy via GitHub Actions:
   - Workflow: "Terraform Plan and Apply"
   - Configuration: `res-dlp-policy`
   - Vars file: `my-policy.tfvars`

---

## Common DLP Patterns

### Pattern 1: Block Everything Except Essentials

**Use Case**: Maximum security, explicitly allow only trusted connectors

```hcl
display_name = "High Security - Block All Except Approved"
description = "Default-deny policy for sensitive environments"

# Block everything by default
default_connectors_classification = "Blocked"

# Explicitly allow only these trusted connectors
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_teams"
    default_action_rule_behavior = "Allow"
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_office365users"
    default_action_rule_behavior = "Allow"
  }
]

# Apply to production environments only
environment_type = "OnlyEnvironments"
environments = [
  "00000000-0000-0000-0000-000000000001"  # Production environment ID
]
```

---

### Pattern 2: Department-Specific Policy

**Use Case**: Different security requirements for different departments

```hcl
display_name = "Finance Department - Data Protection"
description = "Finance-specific connector restrictions"

default_connectors_classification = "Blocked"

# Finance-approved connectors
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
    
    # Allow read-only operations, block destructive ones
    action_rules = [
      { action_id = "DeleteItem_V2", behavior = "Block" },
      { action_id = "ExecutePassThroughNativeQuery_V2", behavior = "Block" }
    ]
    
    # Only allow connections to finance databases
    endpoint_rules = [
      { endpoint = "finance-db.database.windows.net", behavior = "Allow", order = 1 },
      { endpoint = "*", behavior = "Block", order = 2 }
    ]
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
    
    # Finance document libraries only
    endpoint_rules = [
      { endpoint = "contoso.sharepoint.com/sites/finance", behavior = "Allow", order = 1 },
      { endpoint = "*", behavior = "Block", order = 2 }
    ]
  }
]

# Apply only to finance environments
environment_type = "OnlyEnvironments"
environments = ["<finance-prod-env-id>", "<finance-uat-env-id>"]
```

---

### Pattern 3: Graduated Security (Three-Tier)

**Use Case**: Balance security with productivity across different data classifications

```hcl
display_name = "Three-Tier Data Classification"
description = "Business, Non-Business, and Blocked categories"

default_connectors_classification = "Blocked"

# BUSINESS DATA: Internal systems (can share data with each other)
business_connectors = [
  { id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline" },
  { id = "/providers/Microsoft.PowerApps/apis/shared_sql" },
  { id = "/providers/Microsoft.PowerApps/apis/shared_commondataservice" }
]

# NON-BUSINESS DATA: External services (can share with each other, not with Business)
non_business_connectors = [
  { id = "/providers/Microsoft.PowerApps/apis/shared_twitter" },
  { id = "/providers/Microsoft.PowerApps/apis/shared_rss" }
]

# BLOCKED: High-risk connectors (cannot be used at all)
# Everything else defaults to "Blocked" due to default_connectors_classification
```

---

### Pattern 4: Development vs Production

**Use Case**: More permissive in dev, locked down in prod

**Development Policy**:
```hcl
display_name = "Development - Flexible Policy"
description = "Permissive policy for development environments"

# Allow most things, block only high-risk
default_connectors_classification = "Business"

# Explicitly block high-risk connectors
blocked_connectors = [
  { id = "/providers/Microsoft.PowerApps/apis/shared_sendgrid" },
  { id = "/providers/Microsoft.PowerApps/apis/shared_mailchimp" }
]

environment_type = "ExceptEnvironments"
environments = ["<prod-env-id>"]  # Exclude production
```

**Production Policy**:
```hcl
display_name = "Production - Strict Policy"
description = "Restrictive policy for production environments"

default_connectors_classification = "Blocked"

# Only pre-approved connectors
business_connectors = [
  # Minimal approved list
]

environment_type = "OnlyEnvironments"
environments = ["<prod-env-id>"]
```

---

## Managing tfvars Files

### Organization Strategy

Organize your policy files for maintainability:

```
configurations/res-dlp-policy/tfvars/
├── global/
│   └── baseline-security.tfvars        # Company-wide baseline
├── departments/
│   ├── finance.tfvars                  # Finance-specific
│   ├── hr.tfvars                       # HR-specific
│   ├── sales.tfvars                    # Sales-specific
│   └── it.tfvars                       # IT-specific
├── environments/
│   ├── prod-strict.tfvars              # Production
│   ├── uat-moderate.tfvars             # UAT
│   └── dev-permissive.tfvars           # Development
└── templates/
    ├── template.tfvars                 # Full example
    └── minimal.tfvars                  # Minimal example
```

### Naming Conventions

Use consistent, descriptive names:

```bash
# Good naming patterns
finance-prod-dlp.tfvars
hr-confidential-data.tfvars
dev-permissive.tfvars
global-baseline.tfvars

# Avoid generic names
policy1.tfvars
test.tfvars
new.tfvars
```

---

## Onboarding Existing DLP Policies

### When to Use the Generator

**Use the generator utility when**:
- Migrating from manually-created policies
- Adopting IaC for existing governance
- Need to replicate policies across tenants
- Want to backup current configuration

### Step-by-Step Migration

**Step 1: Export Existing Policies**

```bash
cd configurations/utl-export-dlp-policies
```

Deploy this configuration to export all current policies:
- Workflow: "Terraform Plan and Apply"
- Configuration: `utl-export-dlp-policies`
- Apply: Yes

This creates a JSON file with all your policies.

**Step 2: Generate Terraform Configuration**

```bash
cd configurations/utl-generate-dlp-tfvars
```

Create a tfvars file:
```hcl
source_policy_name = "Your Existing Policy Name"
output_file_name   = "migrated-policy.tfvars"
```

Deploy:
- Configuration: `utl-generate-dlp-tfvars`
- This generates a ready-to-use tfvars file!

**Step 3: Review Generated Configuration**

Download the generated tfvars artifact from the workflow and review:
- Connector classifications
- Environment assignments
- Action rules and endpoint filters

**Step 4: Apply as Terraform-Managed**

⚠️ **Important**: You cannot import DLP policies. You must:
1. Delete the manual policy
2. Apply the Terraform configuration
3. Or use a different display_name

```bash
# Option 1: Different name (safest)
display_name = "Your Existing Policy Name - Terraform Managed"

# Option 2: Delete manual policy first (in Admin Center)
# Then use the original name
```

---

## Working with Connectors

### Finding Connector IDs

**Method 1: Export All Connectors**

```bash
cd configurations/utl-export-connectors
```

Deploy this to get a complete list of available connectors with their IDs.

**Method 2: Common Connectors Reference**

```hcl
# Microsoft 365 Core Services
"/providers/Microsoft.PowerApps/apis/shared_sharepointonline"    # SharePoint
"/providers/Microsoft.PowerApps/apis/shared_office365"           # Outlook
"/providers/Microsoft.PowerApps/apis/shared_teams"               # Teams
"/providers/Microsoft.PowerApps/apis/shared_office365users"      # O365 Users
"/providers/Microsoft.PowerApps/apis/shared_onedrive"            # OneDrive

# Data Sources
"/providers/Microsoft.PowerApps/apis/shared_sql"                 # SQL Server
"/providers/Microsoft.PowerApps/apis/shared_azureblob"           # Azure Blob
"/providers/Microsoft.PowerApps/apis/shared_commondataservice"   # Dataverse

# External Services
"/providers/Microsoft.PowerApps/apis/shared_twitter"             # Twitter
"/providers/Microsoft.PowerApps/apis/shared_gmail"               # Gmail
"/providers/Microsoft.PowerApps/apis/shared_dropbox"             # Dropbox
```

### Advanced Connector Configuration

**Action Rules: Control Specific Operations**

```hcl
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
    
    # Block dangerous operations
    action_rules = [
      { action_id = "DeleteItem_V2", behavior = "Block" },
      { action_id = "ExecutePassThroughNativeQuery_V2", behavior = "Block" },
      { action_id = "ExecuteProcedure_V2", behavior = "Block" }
    ]
  }
]
```

**Endpoint Rules: Restrict by URL**

```hcl
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
    
    # Only allow specific SharePoint sites
    endpoint_rules = [
      { endpoint = "contoso.sharepoint.com/sites/approved-site", behavior = "Allow", order = 1 },
      { endpoint = "contoso.sharepoint.com/sites/finance", behavior = "Allow", order = 2 },
      { endpoint = "*", behavior = "Block", order = 3 }
    ]
  }
]
```

**Custom Connector Patterns**

```hcl
# Block all custom connectors by default
custom_connectors_patterns = [
  { order = 1, host_url_pattern = "*", data_group = "Blocked" }
]

# Allow only internal APIs
custom_connectors_patterns = [
  { order = 1, host_url_pattern = "*.internal.company.com", data_group = "Business" },
  { order = 2, host_url_pattern = "*", data_group = "Blocked" }
]
```

---

## Testing and Validation

### Pre-Deployment Checklist

Before deploying a policy:

- [ ] **Display name is unique** (max 50 characters)
- [ ] **Description is clear and accurate**
- [ ] **Connector IDs are correct** (case-sensitive!)
- [ ] **Environment IDs are valid** (if using OnlyEnvironments)
- [ ] **Action rules use correct action_id values**
- [ ] **Endpoint patterns are properly ordered**
- [ ] **Run Terraform plan first** (never apply without reviewing)

### Testing Your Policy

**Step 1: Deploy to Test Environment First**

```hcl
# Test in non-production first
environment_type = "OnlyEnvironments"
environments = ["<test-environment-id>"]
```

**Step 2: Verify in Admin Center**

1. Go to https://admin.powerplatform.microsoft.com
2. Navigate to "Policies" → "Data policies"
3. Find your policy
4. Review all settings match your configuration

**Step 3: Test with Real Apps**

1. Open Power Apps maker portal
2. Try to create an app with blocked connectors
3. Verify error messages appear
4. Try approved connectors
5. Confirm they work as expected

**Step 4: Expand to Production**

Once validated, update environment assignment:

```hcl
environment_type = "OnlyEnvironments"
environments = [
  "<test-environment-id>",
  "<prod-environment-id>"  # Add production
]
```

---

## Policy Precedence and Conflicts

### How Multiple Policies Interact

**Rules**:
1. Most restrictive policy wins
2. Policies are additive in their restrictions
3. Newer policies override older ones for the same environment

**Example Conflict**:
```
Policy A: SharePoint = Business
Policy B: SharePoint = Blocked

Result: SharePoint is BLOCKED (most restrictive wins)
```

### Best Practices

1. **Use clear naming** that indicates precedence:
   ```
   001-global-baseline.tfvars
   002-department-override.tfvars
   003-environment-specific.tfvars
   ```

2. **Document policy interactions** in descriptions:
   ```hcl
   description = "Finance policy - overrides global baseline for finance environments"
   ```

3. **Test together** when deploying multiple policies

---

## Troubleshooting

### Error: "Connector not found"

**Symptom**:
```
Error: Connector ID not valid or not available
```

**Solutions**:
1. Run `utl-export-connectors` to get current connector list
2. Verify connector ID is exact (case-sensitive)
3. Check if connector is available in your tenant/region
4. Use the API name, not the display name

---

### Error: "Policy conflicts with existing policy"

**Symptom**:
```
Error: DLP policy conflicts detected
```

**Solutions**:
1. Review existing policies in Admin Center
2. Check for duplicate environment assignments
3. Resolve connector classification conflicts
4. Update or remove conflicting policy

---

### Error: "Environment not found"

**Symptom**:
```
Error: Environment ID is not valid
```

**Solutions**:
1. Get environment ID from Admin Center:
   - Go to Environments
   - Click environment
   - Copy ID from URL or details
2. Verify format is a valid GUID
3. Check environment still exists

---

### Error: "Action ID not recognized"

**Symptom**:
```
Error: Invalid action_id in action_rules
```

**Solutions**:
1. Action IDs are connector-specific
2. Export the connector details to see valid action IDs
3. Common format: `ActionName_V2` (e.g., `DeleteItem_V2`)
4. Check provider documentation for valid actions

---

## Performance Optimization

### Deployment Speed

**DLP policies deploy in ~30-60 seconds**

Tips for faster deployments:
- Remove unnecessary comments from tfvars
- Use consistent formatting
- Minimize endpoint and action rules
- Combine related policies when possible

### Managing Many Policies

**Use workspace selectors in GitHub Actions**:
```yaml
# Deploy multiple policies in parallel
strategy:
  matrix:
    policy: [finance, hr, sales, it]
```

---

## Best Practices Summary

### Security

✅ **DO**:
- Use `default_connectors_classification = "Blocked"` for maximum security
- Explicitly allow only required connectors
- Test in non-production first
- Review all policies quarterly
- Use endpoint filtering for sensitive connectors

❌ **DON'T**:
- Use `"Business"` as default unless intentional
- Skip testing before production deployment
- Forget to document policy intent
- Overlook action rules for destructive operations

### Maintainability

✅ **DO**:
- Use descriptive display names
- Add detailed descriptions
- Organize tfvars in logical folders
- Version control all policy changes
- Document exceptions and overrides

❌ **DON'T**:
- Use generic names like "Policy1"
- Skip descriptions
- Scatter files randomly
- Make undocumented changes

### Operational

✅ **DO**:
- Plan before apply (always!)
- Monitor policy effectiveness
- Collect user feedback
- Adjust based on real usage
- Keep policies aligned with business needs

❌ **DON'T**:
- Apply without review
- Set-and-forget policies
- Ignore user complaints
- Block legitimate business needs

---

## Next Steps

### Further Learning

- **[Tutorial: First DLP Policy](../tutorials/02-first-dlp-policy.md)** - Hands-on learning
- **[Configuration Catalog](../reference/configuration-catalog.md)** - All configuration options
- **[Architecture Decisions](../explanations/architecture-decisions.md)** - Why things work this way

### Advanced Topics

- Integrating with Azure Policy
- Automated policy testing
- Policy as Code in CI/CD
- Cross-tenant policy management

---

## Reference Links

- **[Power Platform DLP Documentation](https://learn.microsoft.com/power-platform/admin/wp-data-loss-prevention)**
- **[Terraform Provider Documentation](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs/resources/data_loss_prevention_policy)**
- **[Configuration README](../../configurations/res-dlp-policy/README.md)**

---

**Last Updated**: 2025-01-06  
**Version**: 1.0.0  
**Feedback**: [Share your suggestions](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
