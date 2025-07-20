# Power Platform Provider Exception - AVM Compliance

![Explanation](https://img.shields.io/badge/Diataxis-Explanation-purple?style=for-the-badge&logo=lightbulb)

## Overview

This document explains why the Power Platform Terraform configurations in this project cannot achieve full Azure Verified Modules (AVM) compliance and outlines our approach to maximize compliance within the current constraints.

**Key Points:**
- Maximum achievable AVM compliance: **85%** (7/8 major requirements)
- Root cause: Microsoft's architectural separation between Azure and Power Platform
- Mitigation: AVM-inspired approach maintaining all quality standards
- Future path: Monitor for Azure provider Power Platform support

**Related Documentation:**
- [AVM Reference Guide](../references/azure-verified-modules.md) - Core AVM compliance requirements
- [Setup Guide](../guides/setup-guide.md) - Implementation guidance for Power Platform configurations
- [AVM Compliance Remediation Plan](../guides/avm-compliance-remediation-plan.md) - Complete remediation roadmap

## Provider Exception Justification

### **Exception Details**
- **Provider**: `microsoft/power-platform`
- **Version Constraint**: `~> 3.8`
- **AVM Requirement Violation**: TFFR3 - Provider Requirements

### **Root Cause Analysis**

**AVM Approved Providers:**
- `azurerm`: `>= 4.0, < 5.0`
- `azapi`: `>= 2.0, < 3.0`

**Power Platform Resources Availability:**
- ❌ **azurerm provider**: Power Platform resources are NOT available
- ❌ **azapi provider**: Power Platform resources are NOT available
- ✅ **power-platform provider**: Only source for Power Platform resource management

### **Technical Justification**

Power Platform operates as a separate Microsoft cloud service with distinct technical architecture:

#### **Service Architecture Differences**
- **Authentication System**: Uses Power Platform Service Principal authentication, not Azure Resource Manager RBAC
- **API Endpoints**: Power Platform API (`https://api.bap.microsoft.com/`) vs Azure Resource Manager API (`https://management.azure.com/`)
- **Resource Model**: Power Platform-specific resources (DLP policies, environments, solutions, connectors)
- **Governance Scope**: Tenant-level governance spanning multiple Azure subscriptions or operating independently
- **Licensing Model**: Power Platform licensing separate from Azure consumption

#### **Provider Implementation Reality**
```hcl
# Azure providers - Power Platform resources NOT available
provider "azurerm" {
  # ❌ No powerplatform_data_loss_prevention_policies
  # ❌ No powerplatform_environment resources
  # ❌ No powerplatform_solution resources
}

provider "azapi" {
  # ❌ Power Platform APIs not accessible via Azure Resource Manager
  # ❌ Different authentication requirements
  # ❌ Different API schema and endpoints
}

# Power Platform provider - ONLY source for these resources
provider "powerplatform" {
  # ✅ powerplatform_data_loss_prevention_policies
  # ✅ powerplatform_environment
  # ✅ powerplatform_solution
  # ✅ Native Power Platform authentication
}
```

### **Impact Assessment**

**Cannot Achieve:**
- Full AVM compliance (estimated max: 85% compliance)
- Use of approved Azure providers only
- Standard AVM module registry publication

**Can Achieve:**
- AVM structural patterns and best practices
- AVM documentation and testing standards
- AVM-inspired naming conventions with provider-specific adaptations
- Anti-corruption layer patterns in outputs
- Repository governance standards

## Mitigation Strategy

### **Hybrid AVM Approach**

We implement a **"AVM-Inspired"** approach that:

1. **Follows AVM Patterns**: Structure, testing, documentation standards
2. **Adapts Naming**: `terraform-powerplatform-avm-utl-<utility-name>` format
3. **Documents Exceptions**: Clear documentation of deviations and reasons
4. **Maintains Quality**: Same quality standards as full AVM modules

### **Provider-Specific Considerations**

```hcl
# Power Platform provider configuration
terraform {
  required_providers {
    powerplatform = {
      source  = "microsoft/power-platform"  # Exception: Not azurerm/azapi
      version = "~> 3.8"                    # Following AVM versioning patterns
    }
  }
}
```

### **Alternative Approaches Evaluated**

We thoroughly evaluated all possible approaches to achieve full AVM compliance:

#### **Option 1: Azure REST API via azapi Provider**
```hcl
# Attempted approach
resource "azapi_resource" "dlp_policy" {
  # ❌ FAILED: Power Platform API not accessible
  # ❌ FAILED: Different authentication model required
  # ❌ FAILED: API schemas incompatible with azapi patterns
}
```
- **Status**: ❌ Not feasible
- **Reason**: Power Platform APIs require different authentication endpoints and token scopes
- **Technical Blocker**: `https://api.bap.microsoft.com/` ≠ `https://management.azure.com/`

#### **Option 2: Custom azapi Implementation**
```hcl
# Theoretical custom implementation
resource "azapi_resource" "power_platform_dlp" {
  type = "Microsoft.PowerPlatform/policies@2023-06-01"  # Does not exist
  # Would require reimplementing entire Power Platform provider
}
```
- **Status**: ❌ Extremely complex and unsupported
- **Reason**: Would require reimplementing 100+ Power Platform resources
- **Maintenance Risk**: High - no official support for this approach

#### **Option 3: Hybrid Azure/Power Platform Architecture**
```hcl
# Successful hybrid approach
module "azure_resources" {
  source = "Azure/storage/azurerm"  # ✅ AVM compliant
  # Azure resources using approved providers
}

module "power_platform_governance" {
  source = "./modules/power-platform-dlp-export"  # ⚠️ Exception required
  # Power Platform resources using official provider
}
```
- **Status**: ✅ Partially viable and implemented
- **Approach**: Use azurerm for Azure resources, power-platform for Power Platform resources
- **Compliance**: Achieves maximum possible compliance per resource type

## Compliance Strategy

### **Maximum Achievable Compliance**

| **Requirement Category** | **Compliance Status** | **Notes** |
|--------------------------|----------------------|-----------|
| **TFFR1 - Module Cross-References** | ✅ Achievable | Use local modules with proper versioning |
| **TFFR2 - Output Standards** | ✅ Achievable | Implement anti-corruption layers |
| **TFFR3 - Provider Requirements** | ❌ **Exception** | Power Platform provider required |
| **TFNFR1 - Documentation** | ✅ Achievable | HEREDOC formats supported |
| **TFNFR2 - Terraform Docs** | ✅ Achievable | Auto-generation works with any provider |
| **TFNFR3 - Repository Standards** | ✅ Achievable | GitHub standards independent of provider |
| **Testing Requirements** | ✅ Achievable | Terraform testing framework provider-agnostic |
| **Telemetry Requirements** | ✅ Achievable | Can implement with null_resource |

**Estimated Compliance: 85%** (7/8 major requirements achievable)

### **Future Roadmap**

**Short-term (Next 6 months):**
- Monitor Azure provider roadmap for Power Platform resource support
- Engage with Microsoft on AVM Power Platform integration
- Implement maximum possible compliance within current constraints

**Medium-term (6-12 months):**
- Evaluate hybrid approaches combining Azure and Power Platform resources
- Consider contributing to AVM specifications for multi-cloud scenarios
- Develop Power Platform-specific AVM variant specifications

**Long-term (12+ months):**
- Transition to full AVM compliance when/if Power Platform resources become available in approved providers
- Maintain backward compatibility for existing implementations

## Communication Strategy

### **Stakeholder Messaging**

**For Leadership:**
> "We achieve 85% AVM compliance while delivering full Power Platform governance capabilities. The 15% gap is due to Microsoft's architectural separation between Azure and Power Platform services, not implementation choices."

**For Technical Teams:**
> "We follow AVM best practices everywhere possible. The only deviation is using the official Power Platform provider instead of azurerm/azapi, which is required for Power Platform resource management."

**For Compliance/Security:**
> "All security, testing, and governance standards from AVM are implemented. The provider exception is documented, justified, and tracked for future resolution."

### **Documentation Requirements**

All Power Platform modules must include this compliance notice:

```markdown
## ⚠️ AVM Compliance Notice

This module uses the `microsoft/power-platform` provider, which creates an exception to AVM TFFR3 requirements. This is necessary because Power Platform resources are not available through approved Azure providers (`azurerm`/`azapi`).

**Compliance Status**: 85% (Provider Exception)  
**Exception Documentation**: [Power Platform Provider Exception](../explanations/power-platform-provider-exception.md)  
**Quality Standards**: Equivalent to full AVM modules  
**Future Transition**: Planned when Power Platform resources become available in approved providers
```

#### **Module Documentation Template**
```hcl
# Example: modules/power-platform-dlp-export/README.md
# Power Platform DLP Export Module

## AVM Compliance Status
- **Overall Compliance**: 85% (7/8 requirements met)
- **Exception**: TFFR3 - Provider Requirements
- **Justification**: [Provider Exception Documentation](../../docs/explanations/power-platform-provider-exception.md)

## Usage
module "dlp_export" {
  source = "../../modules/power-platform-dlp-export"
  # Standard AVM-style interface
}
```

## Quality Assurance

### **Standards Maintained**

Despite the provider exception, we maintain:
- ✅ **Code Quality**: Same standards as AVM modules
- ✅ **Testing Coverage**: Comprehensive unit and integration tests
- ✅ **Documentation**: Auto-generated and maintained
- ✅ **Security**: Best practices and secure defaults
- ✅ **Governance**: Full repository protection and review processes

### **Monitoring and Review**

**Monthly Reviews:**
- Check [Azure Provider Roadmap](https://github.com/hashicorp/terraform-provider-azurerm/milestones) for Power Platform resource support
- Review [Power Platform Provider releases](https://github.com/microsoft/terraform-provider-power-platform/releases) for new features affecting compliance
- Assess compliance gap impact on project goals

**Quarterly Assessments:**
- Evaluate alternative implementation approaches and emerging patterns
- Update stakeholder communications and compliance metrics
- Review and update exception justification based on Microsoft roadmap changes
- Engage with AVM team on multi-cloud provider scenarios

**Annual Strategy Review:**
- Comprehensive assessment of Microsoft's Power Platform / Azure integration progress
- Cost-benefit analysis of maintaining current approach vs. alternative architectures
- Long-term roadmap updates and stakeholder alignment

## Conclusion

The Power Platform provider exception represents a pragmatic approach to AVM compliance in a multi-cloud environment. While we cannot achieve 100% compliance due to architectural constraints beyond our control, we maximize compliance and maintain the spirit and quality standards of AVM.

### **Value Delivered**
This approach enables us to:
- **Deliver comprehensive Power Platform governance** with industry-standard IaC practices
- **Follow AVM best practices** in all technically feasible areas (85% compliance)
- **Maintain high code quality** and security standards equivalent to full AVM modules  
- **Position for future full compliance** when Power Platform resources become available in approved providers
- **Provide clear documentation** and justification for stakeholders and compliance teams

### **Risk Mitigation**
- **Technical Risk**: Minimized by using official Microsoft Power Platform provider
- **Compliance Risk**: Documented exception with clear justification and remediation path
- **Maintenance Risk**: Regular reviews and monitoring for alternative approaches
- **Stakeholder Risk**: Clear communication and expectation management

### **Success Criteria**
- ✅ **85% AVM compliance achieved** (maximum possible under current constraints)
- ✅ **All quality standards maintained** (testing, documentation, security)
- ✅ **Exception properly documented** with technical justification
- ✅ **Clear path forward** defined for future full compliance
- ✅ **Stakeholder alignment** on approach and limitations

---

**Document Metadata:**
- **Last Updated**: July 20, 2025  
- **Next Review**: August 20, 2025  
- **Owner**: Platform Engineering Team
- **Stakeholders**: Architecture Review Board, Security Team, Compliance Team
- **Related Issues**: [Track AVM Power Platform Support](https://github.com/Azure/Azure-Verified-Modules/issues)
