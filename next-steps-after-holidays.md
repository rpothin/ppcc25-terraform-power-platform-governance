# Next Steps After Holidays

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

> **Purpose:** This plan documents the prioritized next steps for Power Platform governance automation to resume after holidays.

---

## 1. Test Terraform Destroy Workflow - **COMPLETED** ✅
- Use `terraform-destroy.yml` workflow.
- Target: `example.tfvars` file.
- Validate safe and auditable resource destruction.

> [!WARNING]
> Output Delimiter Issue Identified and fixed pushed but not yet tested.

## 2. Test DLP Policy Onboarding Process
- Use `copilot-studio-autonomous-agents.tfvars` for onboarding.
- Steps:
  1. Run `terraform-plan-apply.yml` (expect failure).
  2. Run `terraform-import.yml` to import existing resource.
  3. Run plan and apply again (should succeed).
- If duplicate resource is created:
  - Implement a guardrail to prevent duplicates.
  - Consider improving `terraform-import.yml` with resource type choices for supported imports.

### 2.a. Implementation Plan: Guardrails & Import Workflow (Best Practices)

- **Add Terraform-native guardrails to res-dlp-policy module:**
  - Implement a data source to query existing DLP policies by display name and environment type.
  - Add a `null_resource` with lifecycle precondition to fail the plan if a duplicate is detected, providing a clear error message and import instructions.
  - Make duplicate protection configurable via a variable (e.g., `enable_duplicate_protection`).

- **Enhance input validation:**
  - Enforce display name format, environment type consistency, and required environment assignments in `variables.tf`.
  - Use Terraform variable validation blocks for early error detection.

- **Improve import workflow:**
  - Update `terraform-import.yml` to support resource type selection and auto-suggest resource IDs based on configuration and tenant discovery.
  - Add a pre-import step to scan for existing resources and output import commands for the operator.

- **Document onboarding and guardrail logic:**
  - Add a how-to guide in `docs/guides/` for DLP policy import and duplicate protection.
  - Include troubleshooting steps for common onboarding issues (e.g., duplicate detection, import errors).

- **Test and validate:**
  - Run onboarding scenarios with and without existing resources to confirm guardrail effectiveness.
  - Ensure error messages are actionable and guide the operator to resolution.

- **Continuous improvement:**
  - Periodically review guardrail logic and update as Power Platform API or Terraform provider evolves.
  - Gather feedback from operators to refine onboarding and import processes.

## 3. New Configurations for Power Platform Environment Provisioning
- Design and implement new configurations for environment provisioning.
- Include one or more `res-` modules and a `ptn-` module to combine them.

## 4. Add-on: Power Platform VNet Integration
- Create new configuration(s) to add VNet integration feature to Power Platform environments.
- Ensure modularity and reusability for future add-ons.

---

**Review and update this plan upon return to ensure alignment with project goals and recent changes.**

_Last updated: July 30, 2025_
