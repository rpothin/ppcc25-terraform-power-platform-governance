# Utility Modules Catalog

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

This page provides an authoritative catalog of all utility modules in the PPCC25 Power Platform Governance repository. Utility modules are Terraform configurations designed for data export, reporting, and non-resource operations to support governance and migration workflows.

## Available Utility Modules

- [`utl-export-dlp-policies`](../../configurations/utl-export-dlp-policies/README.md)
  - **Purpose:** Export all Data Loss Prevention (DLP) policies in the tenant for reporting, compliance, and migration scenarios.
  - **Inputs:** None required
  - **Outputs:** DLP policy inventory, detailed policy rules
  - **Related Modules:** [`utl-export-connectors`](../../configurations/utl-export-connectors/README.md)
  - **Migration Workflow:** See [Migration Workflow Guide](../guides/migration-workflow.md)
- [`utl-export-connectors`](../../configurations/utl-export-connectors/README.md)
  - **Purpose:** Export all Power Platform connectors and their classifications for governance and DLP policy planning.
  - **Inputs:** Optional timeout
  - **Outputs:** Connector inventory, summary metadata
  - **Related Modules:** [`utl-export-dlp-policies`](../../configurations/utl-export-dlp-policies/README.md)
  - **Migration Workflow:** See [Migration Workflow Guide](../guides/migration-workflow.md)

## Usage

- Reference these modules in your Terraform configurations to automate data exports for governance and migration.
- For migration scenarios, follow the [Migration Workflow Guide](../guides/migration-workflow.md) for step-by-step instructions.

---

_Last updated: 2025-07-27_
