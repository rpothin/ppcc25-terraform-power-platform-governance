# How to Onboard a Manually Managed DLP Policy to Terraform IaC

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

---

## Introduction

This guide shows you how to onboard an existing, manually managed Data Loss Prevention (DLP) policy into Terraform Infrastructure as Code (IaC) management for Power Platform governance. It covers detection of existing resources, import workflow, and built-in guardrails to prevent duplicate policies. Troubleshooting steps for common onboarding issues are included.

### Prerequisites
- Terraform CLI installed
- Power Platform Terraform provider configured
- Access to target environment and DLP policy details (display name, environment type)
- Required permissions for resource import and management

---

## Step 1: Prepare for Onboarding

1. Gather the following details for the DLP policy you want to onboard:
   - Display name
   - Environment type (e.g., production, sandbox)
   - Environment assignment(s)
2. Ensure your Terraform configuration and provider are set up and authenticated (OIDC recommended).
3. Confirm you have access to the target tenant and environment.

---

## Step 2: Detect Existing DLP Policy

1. In your Terraform configuration, use the provided data source to query for existing DLP policies by display name and environment type.
2. Run `terraform plan` to check for duplicate detection:
   - If a duplicate is found, the plan will fail with a clear error message and import instructions.
   - If no duplicate is found, proceed to resource onboarding.

---

## Step 3: Import the Resource

> **Safety Mechanism:** Guardrails are implemented directly in the Terraform configuration (using a data source and a `null_resource` with lifecycle precondition) to prevent creation of duplicate DLP policies. Duplicate protection is configurable via the `enable_duplicate_protection` variable.

1. Run the import workflow using the provided GitHub Action (`terraform-import.yml`) or manually via CLI:
   - Select the resource type (e.g., DLP policy).
   - Provide the resource ID (auto-suggested if using the workflow).
   - Follow the pre-import step to scan for existing resources and output the correct import command.
2. Execute the import command as instructed (e.g., `terraform import <resource> <resource_id>`).
3. Confirm the resource is now managed by Terraform (check state file).

---

## Step 4: Apply Terraform Management

1. Run `terraform plan` and `terraform apply` to bring the resource under IaC management.
2. Verify that no duplicate resource is created and the imported policy is managed as expected.
3. If the plan fails due to duplicate detection, review the error message and follow the import instructions.

---

## Troubleshooting

### Duplicate Detection Errors
- **Error:** "Duplicate DLP policy detected. Import required."
  - **Resolution:** Follow the import instructions provided in the error message. Ensure `enable_duplicate_protection` is set appropriately.

### Import Failures
- **Error:** "Resource ID not found or invalid."
  - **Resolution:** Double-check the resource ID and environment assignment. Use the pre-import scan to confirm details.

### Common Misconfigurations
- Display name format or environment type mismatch
  - **Resolution:** Validate inputs in `variables.tf` and correct any inconsistencies.
- Missing required environment assignments
  - **Resolution:** Ensure all required variables are set and validated.

---

## References
- [Terraform DLP Policy Module README](../../configurations/res-dlp-policy/README.md)
- [Power Platform Terraform Provider Documentation](https://registry.terraform.io/providers/microsoft/powerplatform/latest/docs)
- [Troubleshooting Guide](../guides/troubleshooting.md)
- [Explanation: Guardrail Logic](../explanations/guardrail-logic.md)

---

_This guide is part of the Power Platform governance automation documentation. For feedback or improvements, please open an issue in the repository._
