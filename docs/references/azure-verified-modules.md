# Azure Verified Modules (AVM) - Reference Guide

![Reference](https://img.shields.io/badge/Diataxis-Reference-orange?style=for-the-badge&logo=library)

## Overview

Azure Verified Modules (AVM) is a comprehensive library of Infrastructure as Code (IaC) modules designed to accelerate and standardize Azure deployments. This reference provides authoritative information about AVM module types and the specific criteria required to make Terraform configurations AVM compliant.

## Module Classifications

AVM defines three distinct module classifications, each serving different purposes and audiences:

### 1. Resource Modules

**Definition:** Deploy a primary resource with WAF (Well-Architected Framework) high priority/impact best practice configurations set by default.

**Key Characteristics:**
- **Primary Focus:** Single Azure resource with comprehensive configuration
- **WAF Aligned:** Implements availability zones, firewall rules, enforced Entra ID authentication by default
- **Shared Interfaces:** Includes RBAC, locks, private endpoints (if supported)
- **Related Resources:** MAY include directly related resources (e.g., VM includes disk & NIC)
- **External Dependencies:** MUST NOT deploy external dependencies (e.g., VM won't create vNet/subnet)
- **Scope:** Any Azure resource including configurations (e.g., Microsoft Defender for Cloud Pricing Plans)

**Target Audience:** 
- Architects crafting bespoke architectures with WAF best practices
- Developers creating pattern modules

**Naming Convention:**
- **Terraform:** `terraform-azurerm-avm-res-<resource-provider>-<resource-type>`

### 2. Pattern Modules

**Definition:** Deploy multiple resources, typically using Resource Modules, to accelerate common tasks/deployments/architectures.

**Key Characteristics:**
- **Multi-Resource:** Deploys multiple resources using Resource Modules
- **Architecture Focused:** Based on Azure Architecture Center patterns or official documentation
- **Scalable:** Can be any size, from simple to complex architectures
- **AVM Only:** MUST NOT contain references to non-AVM modules
- **Composable:** Can contain other pattern modules

**Target Audience:** 
- Teams deploying standard architectural patterns with WAF best practices

**Naming Convention:**
- **Terraform:** `terraform-azurerm-avm-ptn-<pattern-name>`

### 3. Utility Modules *(Preview)*

**Definition:** Implement functions or routines that can be flexibly reused in Resource or Pattern modules.

**Key Characteristics:**
- **Function Focused:** Provides reusable functions/routines/helpers
- **No Resources:** MUST NOT deploy Azure resources (except deployment scripts)
- **Reusable:** Designed for flexible reuse across multiple modules
- **Examples:** API endpoint retrieval, environment-specific portal functions

**Target Audience:** 
- Module developers seeking commonly used functions instead of local re-implementation

**Naming Convention:**
- **Terraform:** `terraform-azurerm-avm-utl-<utility-name>`

{{% notice style="important" title="PREVIEW STATUS" %}}
Utility Modules are currently in preview. The definition and requirements are subject to change as the concept matures. Related documentation and workflow elements will be derived from Pattern Module automation.
{{% /notice %}}

## Terraform AVM Compliance Criteria

To be considered AVM compliant, Terraform configurations must meet both **Functional Requirements (TFFR)** and **Non-Functional Requirements (TFNFR)**.

### Core Functional Requirements

#### TFFR1 - Module Cross-References
- **MUST** use HashiCorp Terraform registry references with pinned versions
- **MUST NOT** use git references or non-AVM modules
- **Example:** `source = "Azure/xxx/azurerm" version = "1.2.3"`

#### TFFR2 - Output Standards
- **SHOULD NOT** output entire resource objects (security/schema concerns)
- **SHOULD** output computed attributes as discrete outputs
- **MUST** implement anti-corruption layer pattern
- **SHOULD NOT** output values that are already inputs (except `name`)

#### TFFR3 - Provider Requirements
- **MUST** use only approved Azure providers:
  - `azurerm`: `>= 4.0, < 5.0`
  - `azapi`: `>= 2.0, < 3.0`
- **MUST** use `required_providers` block with pessimistic version constraints (`~>`)

### Key Non-Functional Requirements

#### Documentation Requirements
- **TFNFR1:** Variable/output descriptions MAY span multiple lines using HEREDOC format
- **TFNFR2:** Documentation MUST be auto-generated via Terraform Docs
- **MUST** include `.terraform-docs.yml` configuration file

#### Repository Standards
- **TFNFR3:** MUST implement GitHub branch protection policies:
  - Require pull requests and approvals
  - Dismiss stale reviews on new commits
  - Require linear history
  - Prevent force pushes and deletions
  - Require CODEOWNERS review
  - Enforce for administrators

#### Code Style Requirements
- **TFNFR10:** MUST NOT use double quotes in `ignore_changes` attributes
- Follow consistent formatting and naming conventions
- Implement proper resource lifecycle management

#### Testing Requirements
- MUST include comprehensive testing coverage
- MUST implement automated validation workflows
- MUST validate both successful deployments and error conditions

#### Telemetry Requirements
- MUST implement usage tracking and telemetry collection
- MUST respect customer privacy and data protection requirements

### Shared Requirements (All Languages)

#### Preview Services (SFR1)
- **MAY** use public preview services/features at discretion
- Preview API versions MAY be used when GA features require preview APIs
- Preview features MUST include warning disclaimers in parameter descriptions

#### Security & Compliance
- MUST implement security best practices by default
- MUST support Azure Policy compliance
- MUST follow principle of least privilege

#### Versioning & Release
- MUST use semantic versioning (SemVer)
- MUST maintain compatibility matrices
- MUST document breaking changes

## Validation Levels

AVM specifications include different validation enforcement levels:

- **Manual:** Verified through manual review processes
- **CI/Informational:** Automated checks that provide warnings
- **CI/Enforced:** Automated checks that block releases on failures

## Severity Classifications

Requirements are classified by implementation priority:

- **MUST:** Mandatory requirements for AVM compliance
- **SHOULD:** Recommended practices for optimal functionality
- **MAY:** Optional features at module owner discretion

## Compliance Verification

To verify Terraform module AVM compliance:

1. **Review Module Classification:** Ensure module fits Resource, Pattern, or Utility definition
2. **Validate Functional Requirements:** Check TFFR1-3 compliance
3. **Audit Non-Functional Requirements:** Verify TFNFR standards
4. **Test Shared Requirements:** Confirm SFR compliance
5. **Verify Documentation:** Ensure auto-generated docs and proper descriptions
6. **Check Repository Setup:** Validate branch protection and CODEOWNERS

## Resources

- [Azure Verified Modules Official Documentation](https://azure.github.io/Azure-Verified-Modules/)
- [Terraform AVM Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
- [AVM Template Repository](https://github.com/Azure/terraform-azurerm-avm-template)
- [Terraform Registry AVM Modules](https://registry.terraform.io/namespaces/Azure)

---

*This reference document provides authoritative information about Azure Verified Modules. For implementation guidance, see the [Setup Guide](../guides/setup-guide.md). For conceptual understanding, refer to the [explanations section](../explanations/).*
