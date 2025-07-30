# DLP tfvars Management Guide

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

> This guide shows you how to manage Data Loss Prevention (DLP) policy tfvars for Power Platform governance using Terraform. It explains when to use the generator utility vs. the template, and provides step-by-step instructions for both onboarding existing policies and creating new ones. It also documents how to use `utl-export-connectors` output for configuring business connectors.

---

## When to Use the Generator vs. the Template

- **Generator Utility (`utl-generate-dlp-tfvars`)**: Use this when onboarding existing DLP policies from Power Platform into Terraform. The utility transforms exported policy data into tfvars format for IaC adoption.
- **Template (`template.tfvars`)**: Use this for creating new DLP policies from scratch. The template provides secure defaults and clear documentation, requiring only essential values.

---

## Onboarding Existing DLP Policies (Generator Utility)

1. **Export Policy Data**:
   - Use the Power Platform admin center or CLI to export the target DLP policy.
2. **Run the Generator Utility**:
   - Set `source_policy_name` and `output_file_name` in the generator module (`utl-generate-dlp-tfvars`).
   - Apply the module to generate a tfvars file with all required policy and connector data.
3. **Review and Edit**:
   - Check the generated tfvars file for completeness and accuracy.
   - Edit as needed to match governance requirements.
4. **Apply with Terraform**:
   - Use the generated tfvars file with the appropriate configuration (e.g., `res-dlp-policy`).

---

## Creating a New DLP Policy (Template)

1. **Copy the Template**:
   - Duplicate `configurations/res-dlp-policy/tfvars/template.tfvars` and rename for your policy (e.g., `my-policy.tfvars`).
2. **Edit Essentials**:
   - Fill in `display_name` (must be unique, max 50 chars).
   - Set other variables only if you need to override secure defaults.
3. **Customize Connectors**:
   - Use outputs from `utl-export-connectors` to configure `business_connectors` for sensitive data.
   - Add `blocked_connectors` or custom patterns for advanced scenarios.
4. **Apply with Terraform**:
   - Run: `terraform plan -var-file="path/to/your.tfvars"`
   - Validate and apply as needed.

---

## Using `utl-export-connectors` Output for Business Connectors

- Run the `utl-export-connectors` utility to export all available connectors in your tenant.
- Use the output to identify connector IDs and recommended configurations for `business_connectors` in your tfvars file.
- Example:
  ```hcl
  business_connectors = [
    {
      id = "/providers/Microsoft.PowerApps/apis/shared_sql"
      default_action_rule_behavior = "Allow"
      action_rules = [
        { action_id = "DeleteItem_V2", behavior = "Block" }
      ]
      endpoint_rules = [
        { endpoint = "contoso.com", behavior = "Allow", order = 1 }
      ]
    }
  ]
  ```
- For troubleshooting, refer to the module README and project guides.

---

## Troubleshooting & Best Practices

- Always use OIDC authentication; never hardcode secrets.
- Prefer secure defaults and minimal configuration for new policies.
- Validate all tfvars files with `terraform plan` before applying.
- Reference outputs from utility modules for onboarding existing resources.
- For more details, see:
  - [Baseline Coding Guidelines](../../.github/instructions/baseline.instructions.md)
  - [Terraform IAC Standards](../../.github/instructions/terraform-iac.instructions.md)
  - [Module README](../../configurations/res-dlp-policy/README.md)

---

**Last updated:** July 30, 2025
