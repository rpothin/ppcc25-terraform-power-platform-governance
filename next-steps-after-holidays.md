# Next Steps After Holidays

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

> **Purpose:** This plan documents the prioritized next steps for Power Platform governance automation to resume after holidays.

---

## 1. Test Terraform Destroy Workflow
- Use `terraform-destroy.yml` workflow.
- Target: `example.tfvars` file.
- Validate safe and auditable resource destruction.

## 2. Test DLP Policy Onboarding Process
- Use `copilot-studio-autonomous-agents.tfvars` for onboarding.
- Steps:
  1. Run `terraform-plan-apply.yml` (expect failure).
  2. Run `terraform-import.yml` to import existing resource.
  3. Run plan and apply again (should succeed).
- If duplicate resource is created:
  - Implement a guardrail to prevent duplicates.
  - Consider improving `terraform-import.yml` with resource type choices for supported imports.

## 3. New Configurations for Power Platform Environment Provisioning
- Design and implement new configurations for environment provisioning.
- Include one or more `res-` modules and a `ptn-` module to combine them.

## 4. Add-on: Power Platform VNet Integration
- Create new configuration(s) to add VNet integration feature to Power Platform environments.
- Ensure modularity and reusability for future add-ons.

---

**Review and update this plan upon return to ensure alignment with project goals and recent changes.**

_Last updated: July 30, 2025_
