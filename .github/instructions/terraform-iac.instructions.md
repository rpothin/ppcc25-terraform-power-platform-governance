---
description: "Terraform Infrastructure as Code standards following Azure Verified Modules (AVM) principles"
applyTo: "configurations/**,modules/**"
---

# Terraform Infrastructure as Code Guidelines

## Azure Verified Modules (AVM) Compliance

**Follow AVM principles as the northstar for all Terraform code:**
- Implement AVM-inspired patterns even with Power Platform provider limitations
- Document all AVM compliance exceptions with clear justification
- Maintain AVM quality standards for testing, documentation, and governance
- Plan for future transition to full AVM compliance when technically feasible

### AVM Module Classifications
- **Resource Modules**: Deploy primary resources with WAF best practices (e.g., `res-*`)
- **Pattern Modules**: Deploy multiple resources using composable patterns (e.g., `ptn-*`)
- **Utility Modules**: Provide reusable functions without deploying resources (e.g., `utl-*`)

## Terraform Code Structure and Standards
- Use consistent formatting with `terraform fmt` for all configuration files
- **MANDATORY:** Run `terraform fmt -check` and `terraform validate` before finalizing any configuration or module changes. All files must pass both checks before merge or release.
## Format and Syntax Validation (MANDATORY)

**All Terraform code must pass format and syntax validation before completion or merge:**

- Run `terraform fmt -check` in the configuration or module directory to ensure all files are properly formatted.
- If issues are found, run `terraform fmt` to auto-correct, then re-run `terraform fmt -check`.
- Run `terraform validate` to ensure all files are syntactically correct and provider requirements are met.
- Do not consider a configuration or module complete until both checks pass with no errors.

**This process is required for AVM compliance, CI/CD reliability, and consistent code quality.**
- Implement proper resource naming conventions with descriptive names
- Group related resources logically and use meaningful comments
- Follow HCL best practices for readability and maintainability
- Separate concerns using multiple .tf files (main.tf, variables.tf, outputs.tf, versions.tf)

## Provider and Version Management (TFFR3)

**AVM-Compliant Provider Standards:**
- **MUST** use `required_providers` block with explicit source and version
- **MUST** pin provider versions using pessimistic constraints (`~>`)
- **MUST** use approved Azure providers when possible:
  - `azurerm`: `>= 4.0, < 5.0`
  - `azapi`: `>= 2.0, < 3.0`
- **EXCEPTION**: Power Platform provider (`microsoft/power-platform`) documented with justification
- Maintain compatibility with latest stable Terraform versions (>= 1.5.0)

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 3.0"
    }
    # Use azurerm for Azure resources when possible
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

## Variables and Outputs (TFFR2)

**Variable Standards:**
- Use consistent variable naming with clear descriptions
- Implement validation rules for input variables where appropriate
- Use HEREDOC format for multi-line descriptions (TFNFR1)
- Mark sensitive variables appropriately with `sensitive = true`

**Output Standards (Anti-Corruption Layer):**
- **MUST NOT** output entire resource objects (security/schema concerns)
- **SHOULD** output computed attributes as discrete outputs
- **MUST** implement anti-corruption layer pattern for complex resources
- **SHOULD NOT** output values that are already inputs (except `name`)
- Mark sensitive outputs appropriately with `sensitive = true`

```hcl
# Good: Discrete, useful outputs
output "dlp_policy_id" {
  description = "The unique identifier of the DLP policy"
  value       = powerplatform_data_loss_prevention_policy.this.id
}

# Bad: Exposing entire resource object
output "dlp_policy" {
  value = powerplatform_data_loss_prevention_policy.this
}
```

## Power Platform Specific Guidelines

**Provider Exception Documentation:**
- Use the official `microsoft/power-platform` provider for Power Platform resources
- **AVM Exception**: Power Platform provider not covered by AVM due to resource scope limitations
- Implement AVM-inspired patterns where technically feasible
- Document compliance gaps with clear mitigation strategies
- Plan for future AVM alignment when provider capabilities expand

**Authentication and Security:**
- Implement proper OIDC authentication for secure cloud connections
- Follow the established backend configuration for state management
- Never hardcode sensitive values in configuration files
- Use Azure Key Vault or environment variables for secrets

**Resource Naming and Tagging:**
- Use consistent resource naming conventions with descriptive prefixes
- Include resource tags for governance and cost management where supported
- Follow Power Platform naming conventions for DLP policies and environments

## Configuration Organization

**File Structure (AVM-Inspired):**
- Separate concerns using multiple .tf files (main.tf, variables.tf, outputs.tf, versions.tf)
- Use consistent variable naming and include proper descriptions
- Implement validation rules for input variables where appropriate
- Group outputs logically and mark sensitive outputs appropriately
- Include `.terraform-docs.yml` for auto-generated documentation (TFNFR2)

**Variable Descriptions (TFNFR1):**
- Use HEREDOC format for multi-line descriptions
- Explain purpose, constraints, and examples
- Include validation rules where appropriate
- Document any Power Platform specific requirements

```hcl
variable "dlp_policy_config" {
  type = object({
    display_name        = string
    default_connectors_classification = string
    environment_type    = string
  })
  description = <<DESCRIPTION
Configuration for Data Loss Prevention policy creation.

- display_name: Human-readable name for the DLP policy
- default_connectors_classification: Default classification (Business/NonBusiness)
- environment_type: Target environment type (Production, Sandbox, etc.)

Example:
dlp_policy_config = {
  display_name = "Corporate Data Protection Policy"
  default_connectors_classification = "Business" 
  environment_type = "Production"
}
DESCRIPTION
  validation {
    condition = contains(["Business", "NonBusiness"], var.dlp_policy_config.default_connectors_classification)
    error_message = "Default connectors classification must be either 'Business' or 'NonBusiness'."
  }
}
```

## Infrastructure as Code Best Practices

**Demonstrate proper IaC principles:**
- Use consistent resource naming conventions with descriptive prefixes
- Implement proper state management with remote backends
- Include resource tags for governance and cost management
- Version pin providers using pessimistic constraints (`~>`)
- Structure outputs to be useful for downstream automation
- Include proper lifecycle management for critical resources
- Use data sources to reference existing resources instead of duplicating

**AVM Quality Standards:**
- Implement comprehensive testing coverage
- Include automated validation workflows  
- Validate both successful deployments and error conditions
- Follow semantic versioning (SemVer) for releases
- Maintain compatibility matrices and documentation

**Documentation Requirements:**
- Auto-generate documentation via Terraform Docs (TFNFR2)
- Include usage examples in module README
- Document all variables with clear descriptions
- Provide troubleshooting guidance for common issues
- Reference official Power Platform documentation

## Security and Best Practices

**Security by Design:**
- Never hardcode sensitive values in configuration files
- Use data sources for referencing existing resources
- Implement proper resource dependencies and lifecycle rules
- Include resource tags for governance and cost management
- Follow principle of least privilege for RBAC
- Implement proper secret management patterns

**AVM Security Standards:**
- Support Azure Policy compliance where applicable
- Implement security best practices by default
- Use secure authentication methods (OIDC preferred)
- Validate input parameters for security implications

## State Management and Backend

**AVM-Aligned Backend Configuration:**
- Use Azure Storage backend with OIDC authentication
- Implement proper state locking mechanisms
- Follow the established naming conventions for state files
- Support remote state sharing for multi-environment deployments
- Include proper backup and recovery procedures

**State Security:**
- Never commit state files to version control
- Use secure backend authentication (OIDC preferred)
- Implement state encryption at rest
- Follow least privilege access for state storage
- Document state management procedures for team onboarding

## Terraform Test Writing Best Practices for Performance

**Optimize test performance by minimizing the number of Terraform plan/apply executions:**

- **Consolidate assertions:** Group as many related assertions as possible into a single `run` block using one `command = plan` (or `apply`) instead of creating many separate `run` blocks. This dramatically reduces the number of expensive plan/apply operations and speeds up test execution.
- **Leverage Terraform's test discovery:** Let `terraform test` automatically find and run all `.tftest.hcl` files recursively—avoid unnecessary file checks or manual test file filtering in your workflow.
- **Prefer plan for structure and data checks:** Use `command = plan` for most validation and only use `apply` when you need to test real resource changes or stateful operations.
- **Cache expensive data source calls:** Where possible, use variables to store data source results and reference them in multiple assertions within the same run block.
- **Group tests by execution requirements:** Separate quick validations (structure, syntax) from integration or stateful tests, but keep each group as consolidated as possible.
- **Example:**

```hcl
# Good: All assertions in a single run block
run "comprehensive_validation" {
  command = plan
  assert { condition = can(data.example_resource.id) error_message = "Resource should exist" }
  assert { condition = output.example_output != null error_message = "Output should not be null" }
  # ...more assertions...
}

# Bad: Each assertion in a separate run block (slow)
run "test_1" { command = plan assert { ... } }
run "test_2" { command = plan assert { ... } }
run "test_3" { command = plan assert { ... } }
```

**Result:**
- Reduces test execution time by 60-90% in CI/CD pipelines
- Minimizes redundant provider initialization and API calls
- Improves feedback loop for module and configuration authors