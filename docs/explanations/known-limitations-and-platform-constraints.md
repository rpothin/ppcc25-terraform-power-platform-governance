# Known Limitations and Platform Constraints

![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)

**Purpose**: Common questions and answers about Power Platform + Terraform limitations  
**Audience**: Teams implementing Power Platform IaC  
**Format**: FAQ with practical workarounds

---

## About This Document

Power Platform has intentional security controls that sometimes conflict with Infrastructure as Code automation. This FAQ addresses the most common questions about these limitations and provides practical workarounds.

**Important**: These aren't bugs—they're platform design decisions that prioritize security over automation convenience.

---

## Environment and Application Admin

### Q: Why does `terraform destroy` fail on environment groups with application admins?

**Error you'll see**:
```
Error: Failed to delete system user for application '***' 
in environment 'd55dae23-ebcf-e76d-b63d-bece332f560c'

Expected: [204 200], received: [403] 403 Forbidden 
{"error":{"code":"0x80040225",
"message":"The specified user(Id = {0}) is disabled."}}
```

**Why it happens**:

Power Platform requires system users to be disabled before deletion. This is intentional security design to prevent accidental service disruption. Even manual deletion in the admin center shows:

> "Failed to delete app user: User with SystemUserId= is not disabled. Please disable the user in the organization before attempting to delete."

**Workaround Option 1: Manual cleanup (recommended)**:
```bash
# 1. Go to Power Platform Admin Center
#    https://admin.powerplatform.microsoft.com/

# 2. For each environment:
#    - Navigate to environment settings
#    - Remove application admin assignments
#    - Disable the users if needed

# 3. Then run Terraform:
terraform destroy -var-file="tfvars/your-file.tfvars" -auto-approve
```

**Workaround Option 2: Remove from state**:
```bash
# Remove problematic resources from state
terraform state rm 'module.environment_application_admin["0"].powerplatform_environment_application_admin.this'

# Destroy remaining infrastructure
terraform destroy -var-file="tfvars/your-file.tfvars" -auto-approve

# Still need manual cleanup in Admin Center
```

**Impact**:
- ❌ Cannot fully automate environment group teardown
- ❌ Demo reset requires manual steps
- ✅ Workaround is straightforward
- ✅ Affects cleanup only, not creation

---

### Q: Can application admins be managed via Terraform for creation?

**Answer**: Yes, for creation. No, for deletion.

**What works**:
```hcl
module "environment_application_admin" {
  source = "../res-environment-application-admin"
  
  application_id  = var.app_registration_id
  environment_id  = module.environment.environment_id
}
```
- ✅ Creates application admin assignments
- ✅ Configures proper permissions
- ✅ Repeatable and consistent

**What doesn't work**:
- ❌ Automated cleanup via `terraform destroy`
- ❌ Requires manual disabling before removal

**Best practice**: Accept the manual cleanup step as part of your process. Document it in your runbooks.

---

## Duplicate Detection and Resource Management

### Q: Why doesn't this repository include duplicate detection for DLP policies?

**Short answer**: Because it's fundamentally impossible to do correctly in Terraform.

**The technical limitation**:

Terraform cannot query its own state file within the same configuration that creates resources. This creates a circular dependency:

```terraform
# ❌ IMPOSSIBLE: Cannot query own state
# Resource creation depends on state validation,
# but state validation needs resource creation context

data "powerplatform_data_loss_prevention_policies" "all" {
  # This queries Power Platform API only
  # Does NOT see resources created in same plan
  # Result: Partial validation with false confidence
}
```

**What we tried**:
```terraform
# Complex duplicate detection logic
# - Added 50-100 lines of code
# - Still couldn't detect duplicates in same plan
# - Created false sense of security
# - Violated 200-line simplicity guideline
```

**Why we removed it**:
1. **Technical**: Fundamentally flawed, can't work correctly
2. **Simplicity**: Added complexity without solving problem
3. **Educational**: Distracted from core IaC concepts
4. **Honesty**: False security is worse than no security

**Better approach**:
```bash
# Before creating resources, check manually
terraform plan

# Use naming conventions to prevent duplicates
display_name = "Finance-DLP-v${var.version}"

# If duplicate exists, import it first
terraform import powerplatform_data_loss_prevention_policy.this <policy-id>
```

---

### Q: What if I accidentally create a duplicate policy?

**Answer**: Terraform will create it successfully. Power Platform allows multiple policies with same name.

**Detection**:
```bash
# List all policies to find duplicates
terraform show

# Or query Power Platform directly
az powerplatform dlp policy list
```

**Resolution**:
```bash
# Option 1: Remove from Terraform state
terraform state rm powerplatform_data_loss_prevention_policy.duplicate

# Option 2: Import the existing one
terraform import powerplatform_data_loss_prevention_policy.this <policy-id>

# Option 3: Delete via Admin Center
# Then remove from Terraform state
```

**Prevention strategies**:
1. **Naming conventions**: Include version numbers or dates
2. **Code review**: Always review `terraform plan` before applying
3. **Environment segregation**: Separate tfvars files per environment
4. **Manual checks**: Query existing policies before creating new ones

---

### Q: Should production implementations add duplicate detection?

**Answer**: No, for the same fundamental reasons.

**The reality**:
- Terraform's architecture prevents true duplicate detection within same config
- Partial detection creates false sense of security
- Better to accept limitation and work around it

**Production recommendations**:

**1. Naming conventions**:
```hcl
locals {
  policy_name = "${var.department}-${var.environment}-DLP-${var.version}"
  # Example: "Finance-Production-DLP-v2.1.0"
}
```

**2. Pre-flight checks**:
```bash
# In CI/CD pipeline, before terraform apply
existing_policies=$(az powerplatform dlp policy list --query "[?displayName=='${POLICY_NAME}'].id" -o tsv)

if [ -n "$existing_policies" ]; then
  echo "Policy already exists. Import it or update name."
  exit 1
fi
```

**3. Import existing resources**:
```bash
# If policy exists, import instead of create
terraform import powerplatform_data_loss_prevention_policy.this <policy-id>
```

**4. Code review process**:
- Always require peer review of `terraform plan` output
- Check for unintended new resources
- Verify policy names are unique

---

## Performance and Scaling

### Q: How long does environment creation take?

**Answer**: Depends on whether you include Dataverse.

**Without Dataverse (Lightweight)**:
```hcl
environment = {
  display_name     = "Test Environment"
  environment_type = "Sandbox"
  # No dataverse block
}
```
- ⏱️ Creation time: ~5 minutes
- 💾 Storage: Minimal
- 🎯 Use case: Canvas apps, basic workflows

**With Dataverse (Full Power)**:
```hcl
environment = {
  display_name     = "Production Environment"
  environment_type = "Production"
}

dataverse = {
  language_code = 1033
  currency_code = "USD"
}
```
- ⏱️ Creation time: ~15-20 minutes (sometimes longer)
- 💾 Storage: Database provisioning
- 🎯 Use case: Model-driven apps, complex solutions

**Planning advice**:
- Schedule demos with buffer time
- Create environments ahead of presentations
- Use existing environments for time-sensitive demos

---

### Q: Can I speed up multiple environment creation?

**Answer**: Yes, but with limits.

**Parallel creation works**:
```hcl
module "environments" {
  source   = "../res-environment"
  for_each = local.environments
  # Creates multiple environments in parallel
}
```

**Power Platform limits**:
- Concurrent operations: ~10 environments at once
- Rate limiting: May throttle beyond this
- Dependencies: Some operations must be sequential

**Best practice**:
```hcl
# Group 1: Environments (parallel)
module "environments" {
  source   = "../res-environment"
  for_each = local.environments
}

# Group 2: Settings (after environments exist)
module "settings" {
  source   = "../res-environment-settings"
  for_each = local.environments
  
  depends_on = [module.environments]
}
```

---

## Authentication and Permissions

### Q: What permissions are required for Terraform automation?

**Answer**: It depends on what resources you're managing.

**Minimum for DLP policies**:
- Power Platform Administrator role
- Or custom role with:
  - `Microsoft.PowerApps/dlpPolicies/write`
  - `Microsoft.PowerApps/dlpPolicies/delete`

**For environment management**:
- Dynamics 365 Administrator role
- Or Power Platform Administrator

**For full automation**:
- Global Administrator (not recommended for production)
- Or Power Platform Administrator + appropriate Azure roles

**Best practice**:
```
Least privilege approach:
1. Create service principal
2. Assign minimum required roles
3. Use OIDC authentication (no stored secrets)
4. Scope to specific environments if possible
```

---

### Q: Why use OIDC instead of service principal credentials?

**Answer**: Security and compliance.

**Service principal with stored credentials**:
```yaml
# ❌ Anti-pattern
secrets:
  CLIENT_SECRET: <stored-secret>
```
- ❌ Long-lived credentials (months/years)
- ❌ Stored secrets vulnerable to compromise
- ❌ Hard to rotate regularly
- ❌ Compliance concerns

**OIDC token exchange**:
```yaml
# ✅ Best practice
permissions:
  id-token: write
```
- ✅ Short-lived tokens (minutes)
- ✅ No stored secrets
- ✅ Automatic rotation
- ✅ Audit trail for every token
- ✅ Least privilege by default

**How it works**:
```
1. GitHub Actions requests OIDC token from GitHub
2. GitHub validates workflow identity
3. Token exchanged for Azure AD token
4. Token used for Power Platform operations
5. Token expires after operation completes
```

---

## Configuration and State Management

### Q: Should I commit tfvars files to Git?

**Answer**: Depends on content.

**Safe to commit**:
```hcl
# tfvars/dev.tfvars
display_name = "Development DLP Policy"
environment_type = "Development"
default_connectors_classification = "Business"
```
- ✅ No secrets
- ✅ Environment configuration
- ✅ Version controlled

**Never commit**:
```hcl
# ❌ Contains secrets
client_id     = "12345678-1234-1234-1234-123456789012"
client_secret = "secret-value-here"
tenant_id     = "87654321-..."
```

**Best practice**:
```gitignore
# .gitignore
*.secret.tfvars
terraform.tfvars
.terraform/
*.tfstate
*.tfstate.backup
```

**For secrets**:
```yaml
# GitHub Actions workflow
env:
  TF_VAR_client_id: ${{ secrets.AZURE_CLIENT_ID }}
  TF_VAR_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
```

---

### Q: Where should I store Terraform state?

**Answer**: Remote backend, never local.

**Wrong approach**:
```hcl
# ❌ Local state file
# terraform.tfstate in repository
```
- ❌ No collaboration
- ❌ No state locking
- ❌ Risk of state conflicts
- ❌ No backup/recovery

**Correct approach**:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"
    container_name       = "tfstate"
    key                  = "ppcc25-governance.tfstate"
    use_oidc            = true
  }
}
```
- ✅ Team collaboration
- ✅ State locking prevents conflicts
- ✅ Backup and versioning
- ✅ Secure access via OIDC

---

## Testing and Validation

### Q: How do I test Terraform changes without affecting production?

**Answer**: Multiple strategies available.

**Strategy 1: Separate tfvars files**:
```bash
# Test with dev configuration
terraform plan -var-file="tfvars/dev.tfvars"
terraform apply -var-file="tfvars/dev.tfvars"

# Only after verification
terraform plan -var-file="tfvars/prod.tfvars"
```

**Strategy 2: Preview changes**:
```bash
# Always review plan before applying
terraform plan -out=changes.tfplan

# Review the plan file
terraform show changes.tfplan

# Apply only if confident
terraform apply changes.tfplan
```

**Strategy 3: Canary deployment**:
```hcl
# Step 1: Apply to single test environment
environment_type = "OnlyEnvironments"
environments     = ["test-env-id"]

# Step 2: After validation, expand
environments = ["test-env-id", "prod-env-1", "prod-env-2"]
```

**Strategy 4: GitHub environment protection**:
```yaml
# .github/workflows/terraform-apply.yml
environment:
  name: production  # Requires approval
```

---

## Troubleshooting

### Q: What do I do when Terraform gets "stuck"?

**Answer**: Depends on the symptoms.

**Symptom: State lock errors**:
```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc123...
  Operation: OperationTypeApply
```

**Solution**:
```bash
# Verify no other operation running
# If safe, force unlock
terraform force-unlock abc123

# Then retry
terraform apply
```

**Symptom: Provider authentication failures**:
```
Error: Failed to authenticate with Power Platform
```

**Solution**:
```bash
# Check environment variables
echo $POWER_PLATFORM_USE_OIDC
echo $POWER_PLATFORM_CLIENT_ID

# Verify GitHub secrets configured
gh secret list

# Re-run setup script
./scripts/setup/setup-environment.sh
```

**Symptom: "Resource already exists" errors**:
```
Error: A resource with the ID "..." already exists
```

**Solution**:
```bash
# Import existing resource
terraform import <resource_type>.<name> <resource_id>

# Or remove from state if managed externally
terraform state rm <resource_type>.<name>
```

**For more help**: See [Troubleshooting Guide](../guides/troubleshooting.md)

---

## Decision Making

### Q: When should I use Terraform vs Admin Center?

**Answer**: Use the right tool for the situation.

**Use Terraform for**:
- ✅ Repeated operations
- ✅ Multi-environment deployments
- ✅ Configuration that must be consistent
- ✅ Changes requiring audit trail
- ✅ Automated workflows
- ✅ Team collaboration

**Use Admin Center for**:
- ✅ One-off experiments
- ✅ Emergency fixes
- ✅ Exploring new features
- ✅ Operations Terraform doesn't support yet

**Hybrid approach example**:
```
Morning: Use Admin Center to test new DLP policy manually
Afternoon: Codify working policy in Terraform
Next week: Deploy via Terraform to all environments
```

---

### Q: Should everything be in Terraform?

**Answer**: No. Use pragmatic judgment.

**Good candidates for Terraform**:
- DLP policies (change frequently, need consistency)
- Environments (repeatable creation)
- Settings (standardization important)
- Security configurations (audit trail crucial)

**Poor candidates for Terraform**:
- One-time manual configurations
- Frequently changing test environments
- User-specific customizations
- Resources with complex manual workflows

**The test**: "Will I need to repeat this? Does consistency matter?"
- Yes → Terraform
- No → Manual is fine

---

## Getting Help

### Q: Where can I get help with these limitations?

**Answer**: Multiple resources available.

**Documentation**:
- **[Troubleshooting Guide](../guides/troubleshooting.md)** - Common issues and solutions
- **[Architecture Decisions](./architecture-decisions.md)** - Why things work this way
- **[How-to Guides](../guides/)** - Step-by-step solutions

**Community**:
- [GitHub Discussions](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions) - Ask questions
- [GitHub Issues](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/issues) - Report bugs

**Provider documentation**:
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [Provider Issues](https://github.com/microsoft/terraform-provider-power-platform/issues)

---

## Contributing Your Experience

### Q: I found a new limitation. How do I document it?

**Answer**: Follow our documentation standard.

**Template for new limitations**:
```markdown
### Q: [Concise question describing the limitation]

**Error you'll see**:
```
[Exact error message]
```

**Why it happens**:
[Explanation of root cause]

**Workaround**:
[Step-by-step solution]

**Impact**:
- ❌ What doesn't work
- ✅ What does work
- 🔄 Any alternatives
```

**Submit via**:
1. [GitHub Discussion](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions) - For questions
2. [Pull Request](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/pulls) - For documentation updates

---

## Summary

**Key takeaways**:

1. **Some limitations are fundamental** - Accept and work around them
2. **Workarounds exist for most issues** - Usually straightforward
3. **Manual steps are sometimes necessary** - Not everything can be automated
4. **Documentation helps** - Share your experiences with the community
5. **Keep improving** - Contribute back what you learn

**The philosophy**:
```
Perfect automation is impossible.
Good-enough automation with clear
limitations is better than no automation.
```

---

**Last Updated**: 2025-01-06  
**Version**: 2.0.0 (Converted to FAQ format)  
**Contribute**: [Share your experiences](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)