<!-- BEGIN_TF_DOCS -->
# Power Platform Azure VNet Extension Pattern

This configuration orchestrates Azure Virtual Network infrastructure with Power Platform enterprise policies for network injection capabilities, featuring **dynamic per-environment scaling** and following Azure Verified Module (AVM) best practices with Power Platform provider adaptations.

## Key Features

- **🔄 Dynamic Per-Environment IP Allocation**: Automatic IP range calculation supporting 2-16 environments with zero conflicts
- **🌐 Dual VNet Architecture**: Primary and failover regions with mathematically calculated non-overlapping IP ranges
- **📈 Enterprise Scaling**: Base address spaces (`/12`) automatically subdivided into per-environment VNets (`/16`)
- **🏢 Enterprise Policy Integration**: Automatic Power Platform network injection policy deployment
- **🔒 Multi-Subscription Support**: Production and non-production environment segregation
- **🔗 Remote State Integration**: Reads from ptn-environment-group for seamless pattern composition
- **📋 CAF Naming Compliance**: Cloud Adoption Framework naming conventions for all Azure resources
- **🔐 Private Endpoint Support**: Dedicated subnets for secure Azure service connectivity

## Dynamic IP Allocation Architecture

### Base Address Space Approach
Instead of hardcoded IP ranges, this pattern uses **base address spaces** that automatically calculate unique IP ranges for each environment:

```hcl
# Base address spaces provide capacity for multiple environments
network_configuration = {
  primary = {
    vnet_address_space_base = "10.100.0.0/12"  # 1,048,576 IPs → 16 environments
  }
  failover = {
    vnet_address_space_base = "10.112.0.0/12"  # 1,048,576 IPs → 16 environments
  }
}
```

### Per-Environment Allocation Examples

**2 Environments (Non-Prod + Prod):**
- Environment 0: Primary `10.100.0.0/16`, Failover `10.112.0.0/16` (65,536 IPs each)
- Environment 1: Primary `10.101.0.0/16`, Failover `10.113.0.0/16` (65,536 IPs each)

**3 Environments (Dev + Test + Prod):**
- Environment 0 (dev): Primary `10.100.0.0/16`, Failover `10.112.0.0/16`
- Environment 1 (test): Primary `10.101.0.0/16`, Failover `10.113.0.0/16`
- Environment 2 (prod): Primary `10.102.0.0/16`, Failover `10.114.0.0/16`

**4 Environments (Dev + Test + UAT + Prod):**
- Environment 3 (uat): Primary `10.103.0.0/16`, Failover `10.115.0.0/16`

### Subnet Layout per Environment
Each environment gets consistent subnet allocation within its `/16`:
- **Power Platform Subnet**: `.1.0/24` (256 IPs for Power Platform delegation)
- **Private Endpoint Subnet**: `.2.0/24` (256 IPs for Azure service connectivity)

## Use Cases

This configuration is designed for organizations that need to:

1. **🎯 Multi-Environment Network Injection**: Deploy consistent Power Platform network policies across dev, test, and production environments
2. **🔄 Dynamic Environment Scaling**: Support flexible environment counts (2-16) without manual IP planning
3. **🌍 Multi-Region Resilience**: Establish primary and failover VNets in adjacent Azure regions for business continuity
4. **🏢 Production Environment Isolation**: Separate production workloads into dedicated subscriptions with strict network controls
5. **🔒 Private Connectivity**: Enable secure communication between Power Platform and Azure services through private endpoints
6. **📊 Governance at Scale**: Apply consistent network policies across multiple Power Platform environments automatically
7. **🛡️ Zero Trust Architecture**: Implement network-level controls as part of comprehensive Zero Trust security strategy

## Pattern Architecture

This pattern module orchestrates multiple resource modules following AVM principles:

- **res-virtual-network**: Deploys per-environment primary and failover VNets with Power Platform delegation
- **res-enterprise-policy**: Creates Power Platform network injection policies
- **res-enterprise-policy-link**: Links policies to target environments
- **res-private-endpoint**: Provisions private connectivity to Azure services (future)

## Scaling Capabilities

| **Environment Count** | **Total IP Capacity** | **Per-Environment IPs** | **Status** |
|----------------------|----------------------|-------------------------|------------|
| 2 environments       | 262,144 IPs          | 131,072 IPs each       | ✅ **Supported** |
| 3 environments       | 393,216 IPs          | 131,072 IPs each       | ✅ **Supported** |
| 4 environments       | 524,288 IPs          | 131,072 IPs each       | ✅ **Supported** |
| Up to 16 environments| 2,097,152 IPs        | 131,072 IPs each       | ✅ **Enterprise Scale** |

## Environment-Specific Configuration Patterns

### Production Environments
- Dedicated Azure subscription with enhanced security controls
- Automatic IP allocation within production IP ranges
- Stricter network access controls and monitoring
- Dedicated `/16` with 65,536 IPs capacity

### Non-Production Environments
- Shared Azure subscription for cost optimization  
- Automatic IP allocation within non-production IP ranges
- Relaxed network controls for development efficiency
- Each environment gets dedicated `/16` with 65,536 IPs capacity

## Usage with GitHub Actions

```yaml
# GitHub Actions workflow input
inputs:
  configuration: 'ptn-azure-vnet-extension'
  tfvars_file: 'tfvars/regional-examples.tfvars'
  # Environment count is determined automatically from ptn-environment-group
```

## Advanced Pattern Composition

This pattern is designed to extend ptn-environment-group configurations and automatically scales to match the environment count:

```hcl
# Deploy environment group first (defines environment count)
module "environment_group" {
  source = "../ptn-environment-group"
  workspace_name = "ProductionWorkspace"
  environments = ["dev", "test", "prod"]  # 3 environments
}

# VNet extension automatically creates 3 sets of VNets with unique IP ranges
module "vnet_extension" {
  source = "../ptn-azure-vnet-extension"
  workspace_name = "ProductionWorkspace"  # Must match
  network_configuration = {
    primary = {
      vnet_address_space_base = "10.100.0.0/12"  # Auto-scales to 3 environments
    }
    failover = {
      vnet_address_space_base = "10.112.0.0/12"  # Auto-scales to 3 environments
    }
    # ... subnet allocation config
  }
  depends_on = [module.environment_group]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.6)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.117)

- <a name="requirement_powerplatform"></a> [powerplatform](#requirement\_powerplatform) (~> 3.8)

## Providers

The following providers are used by this module:

- <a name="provider_terraform"></a> [terraform](#provider\_terraform)

## Resources

The following resources are used by this module:

- [terraform_remote_state.environment_group](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_network_configuration"></a> [network\_configuration](#input\_network\_configuration)

Description: Dynamic dual VNet network configuration for Power Platform enterprise policies with per-environment scaling.

WHY: Power Platform network injection enterprise policies require dual VNet architecture  
that scales dynamically with environment count while preventing IP conflicts.

CONTEXT: This configuration supports flexible environment deployment (2-N environments)  
with automatic per-environment IP range allocation from base address spaces.

Properties:
- primary.location: Azure region for primary VNets
- primary.vnet\_address\_space\_base: Base CIDR for primary region (e.g., 10.100.0.0/12)
- failover.location: Azure region for failover VNets
- failover.vnet\_address\_space\_base: Base CIDR for failover region (e.g., 10.112.0.0/12)
- subnet\_allocation: Standardized subnet sizing within each environment's /16

Example:  
network\_configuration = {  
  primary = {  
    location                = "Canada Central"  
    vnet\_address\_space\_base = "10.100.0.0/12"  # Supports 16 environments
  }  
  failover = {  
    location                = "Canada East"   
    vnet\_address\_space\_base = "10.112.0.0/12"  # Non-overlapping with primary
  }  
  subnet\_allocation = {  
    power\_platform\_subnet\_size   = 24  # /24 = 256 IPs per environment  
    private\_endpoint\_subnet\_size = 24  # /24 = 256 IPs per environment  
    power\_platform\_offset       = 1   # .1.0/24 within each /16  
    private\_endpoint\_offset      = 2   # .2.0/24 within each /16
  }
}

Dynamic Allocation Examples:
- Environment 0: Primary 10.100.0.0/16, Failover 10.112.0.0/16
- Environment 1: Primary 10.101.0.0/16, Failover 10.113.0.0/16  
- Environment 2: Primary 10.102.0.0/16, Failover 10.114.0.0/16

Validation Rules:
- Base address spaces must be /12 to support up to 16 environments
- Primary and failover ranges must not overlap
- Subnet sizes must be 16-30 (valid Azure subnet sizes)
- Offset values must allow subnets within environment /16

Type:

```hcl
object({
    primary = object({
      location                = string
      vnet_address_space_base = string
    })
    failover = object({
      location                = string
      vnet_address_space_base = string
    })
    subnet_allocation = object({
      power_platform_subnet_size   = number
      private_endpoint_subnet_size = number
      power_platform_offset        = number
      private_endpoint_offset      = number
    })
  })
```

### <a name="input_non_production_subscription_id"></a> [non\_production\_subscription\_id](#input\_non\_production\_subscription\_id)

Description: Azure subscription ID for non-production environments (Dev, Test, Staging).

This subscription will be used to deploy VNet infrastructure for environments  
identified as non-production from the remote state data. Supports multi-subscription  
governance patterns where production and non-production resources are isolated.

Example:  
non\_production\_subscription\_id = "12345678-1234-1234-1234-123456789012"

Validation Rules:
- Must be a valid Azure subscription GUID format
- Must be different from production subscription for proper isolation
- Will be used for all environments with type != "Production"

Type: `string`

### <a name="input_paired_tfvars_file"></a> [paired\_tfvars\_file](#input\_paired\_tfvars\_file)

Description: Tfvars file name (without extension) used by the paired ptn-environment-group deployment.

This must exactly match the tfvars file name used when deploying ptn-environment-group  
to ensure proper remote state reading. The pattern will construct the remote state key  
based on the workflow naming convention: ptn-environment-group-{tfvars-file}.tfstate

Example:  
paired\_tfvars\_file = "regional-examples"

Remote state key will be: "ptn-environment-group-regional-examples.tfstate"

Validation Rules:
- Must be 1-50 characters for consistency with tfvars file naming
- Cannot be empty or contain only whitespace  
- Should match the tfvars file name used in ptn-environment-group deployment
- Must be a valid filename (no special characters except hyphens)

Type: `string`

### <a name="input_production_subscription_id"></a> [production\_subscription\_id](#input\_production\_subscription\_id)

Description: Azure subscription ID for production environments.

This subscription will be used to deploy VNet infrastructure for environments  
identified as "Production" type from the remote state data. Supports multi-subscription  
governance patterns where production and non-production resources are isolated.

Example:  
production\_subscription\_id = "87654321-4321-4321-4321-210987654321"

Validation Rules:
- Must be a valid Azure subscription GUID format
- Must be different from non-production subscription for proper isolation
- Will be used for all environments with type == "Production"

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags to be applied to all Azure resources created by this pattern.

These tags will be applied to resource groups, VNets, subnets, and other  
Azure resources. Useful for cost tracking, governance, and resource management.

Example:  
tags = {  
  Environment = "Demo"  
  Project     = "PPCC25"  
  Owner       = "Platform Team"  
  CostCenter  = "IT-001"
}

Default: {} (no additional tags beyond required governance tags)

Validation Rules:
- Tag keys and values cannot be empty
- Follows Azure tagging best practices
- Will be merged with pattern-specific governance tags

Type: `map(string)`

Default: `{}`

### <a name="input_test_mode"></a> [test\_mode](#input\_test\_mode)

Description: Enable test mode to use mock data instead of remote state.

When set to true, this pattern will use mock environment data instead of  
reading from the actual remote state. This enables comprehensive testing  
without requiring backend infrastructure dependencies.

Example:  
test\_mode = true  # For testing  
test\_mode = false # For production use (default)

Validation Rules:
- Boolean value only
- Defaults to false for production use
- When true, remote state data source is bypassed

Type: `bool`

Default: `false`

## Outputs

The following outputs are exported:

### <a name="output_azure_resource_groups"></a> [azure\_resource\_groups](#output\_azure\_resource\_groups)

Description: Azure Resource Group information for all deployed environments.

Single resource group per Power Platform environment containing both primary  
and failover VNets. Provides resource group IDs, names, and locations across  
production and non-production subscriptions for cleaner governance.

Resource Groups:
- Single RG per Environment: All environment resources in one resource group
- Primary Location: Resource group created in primary Azure region
- Production: Deployed to dedicated production subscription  
- Non-Production: Deployed to shared non-production subscription

### <a name="output_azure_virtual_networks"></a> [azure\_virtual\_networks](#output\_azure\_virtual\_networks)

Description: Azure Virtual Network information for all deployed environments.

Provides VNet resource IDs, names, address spaces, and subnet information for  
both primary and failover VNets across production and non-production subscriptions.  
Critical for downstream modules requiring network integration or private connectivity.

VNet Components:
- Resource ID: Full Azure resource identifier for the VNet
- Address Space: CIDR blocks allocated to each VNet (dynamically calculated)
- Subnets: Power Platform delegated subnets and private endpoint subnets
- Region: Primary and failover region deployment information

### <a name="output_configuration_validation_status"></a> [configuration\_validation\_status](#output\_configuration\_validation\_status)

Description: Comprehensive validation status of the VNet extension pattern configuration.

Reports the validation status of all configuration components including  
remote state integration, environment processing, and network planning.  
Essential for troubleshooting configuration issues before resource deployment.

Validation Components:
- remote\_state\_valid: Remote state from ptn-environment-group is accessible
- environments\_found: Environment data successfully extracted from remote state
- subscriptions\_different: Production and non-production subscriptions are distinct
- subnet\_within\_vnet: Power Platform subnet is properly allocated within VNet space
- names\_generated: CAF-compliant resource names successfully generated

### <a name="output_deployment_status_summary"></a> [deployment\_status\_summary](#output\_deployment\_status\_summary)

Description: Complete deployment status summary for all phases of VNet extension pattern.

Provides comprehensive status information for Azure infrastructure deployment  
including actual resource counts, deployment success metrics, and integration  
status. Critical for monitoring deployment progress and validating completion.

Deployment Components:
- Phase Status: Completion status for all deployment phases
- Resource Counts: Actual deployed Azure resources by type and subscription
- Integration Status: Power Platform policy assignment and VNet integration
- Deployment Metrics: Success rates and deployment validation

### <a name="output_enterprise_policies"></a> [enterprise\_policies](#output\_enterprise\_policies)

Description: Power Platform Enterprise Policy information for all deployed environments.

Provides enterprise policy system IDs, names, and configuration details for  
NetworkInjection policies across production and non-production environments.  
Essential for external integrations and policy management workflows.

Enterprise Policy Components:
- System ID: Power Platform system identifier for the enterprise policy
- Policy Type: NetworkInjection for VNet integration capabilities
- Virtual Networks: Associated VNet resource IDs for network injection
- Location: Power Platform region mapping from Azure regions

### <a name="output_integration_endpoints"></a> [integration\_endpoints](#output\_integration\_endpoints)

Description: VNet integration endpoints for downstream consumption and private connectivity.

Provides structured integration points for downstream modules requiring private  
connectivity to the deployed VNet infrastructure. Essential for storage accounts,  
Key Vaults, and other Azure services requiring private endpoint connectivity.

Integration Components:
- Private Endpoint Subnets: Subnet IDs for private endpoint deployment
- VNet Integration: VNet resource IDs for service integration
- Network Security: Security group and routing information
- DNS Integration: Private DNS zone integration points

### <a name="output_network_planning_summary"></a> [network\_planning\_summary](#output\_network\_planning\_summary)

Description: Summary of network configuration planning for dual VNet architecture validation

### <a name="output_output_schema_version"></a> [output\_schema\_version](#output\_output\_schema\_version)

Description: The version of the output schema for this VNet extension pattern module.

### <a name="output_pattern_configuration_summary"></a> [pattern\_configuration\_summary](#output\_pattern\_configuration\_summary)

Description: Comprehensive summary of VNet extension pattern configuration, compliance, and infrastructure status

### <a name="output_policy_assignments"></a> [policy\_assignments](#output\_policy\_assignments)

Description: Power Platform policy assignment status for all environments.

Provides policy assignment information showing which NetworkInjection enterprise  
policies have been successfully linked to Power Platform environments. Critical  
for validating VNet integration deployment and troubleshooting assignment issues.

Policy Assignment Components:
- Environment ID: Power Platform environment identifier from remote state
- System ID: Associated enterprise policy system identifier
- Policy Type: NetworkInjection for VNet integration
- Assignment Status: Deployment and linking status information

### <a name="output_remote_state_integration_summary"></a> [remote\_state\_integration\_summary](#output\_remote\_state\_integration\_summary)

Description: Summary of remote state integration from ptn-environment-group configuration.

Details the environment data successfully read from the remote state and  
how it's being processed for VNet integration. Critical for verifying  
proper integration between pattern modules.

Remote State Components:
- workspace\_name: Base workspace name from environment group
- environments\_discovered: Count of environments available for VNet integration
- environment\_types: Distribution of environment types (Production, Sandbox, etc.)
- template\_metadata: Template information from the environment group pattern

### <a name="output_resource_naming_summary"></a> [resource\_naming\_summary](#output\_resource\_naming\_summary)

Description: CAF-compliant resource naming summary for all Azure resources.

Shows the generated resource names following Cloud Adoption Framework  
naming conventions. Essential for validating naming consistency and  
ensuring governance compliance across all environments.

Naming Components:
- Base components: Project, workspace, location abbreviations
- Patterns: CAF-compliant naming patterns for each resource type
- Generated names: Actual resource names for each environment
- Validation: Naming rule compliance and uniqueness checks

## Modules

The following Modules are called:

### <a name="module_non_production_enterprise_policies"></a> [non\_production\_enterprise\_policies](#module\_non\_production\_enterprise\_policies)

Source: ../res-enterprise-policy

Version:

### <a name="module_non_production_failover_virtual_networks"></a> [non\_production\_failover\_virtual\_networks](#module\_non\_production\_failover\_virtual\_networks)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: ~> 0.7.0

### <a name="module_non_production_policy_links"></a> [non\_production\_policy\_links](#module\_non\_production\_policy\_links)

Source: ../res-enterprise-policy-link

Version:

### <a name="module_non_production_primary_virtual_networks"></a> [non\_production\_primary\_virtual\_networks](#module\_non\_production\_primary\_virtual\_networks)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: ~> 0.7.0

### <a name="module_non_production_resource_groups"></a> [non\_production\_resource\_groups](#module\_non\_production\_resource\_groups)

Source: Azure/avm-res-resources-resourcegroup/azurerm

Version: ~> 0.1.0

### <a name="module_production_enterprise_policies"></a> [production\_enterprise\_policies](#module\_production\_enterprise\_policies)

Source: ../res-enterprise-policy

Version:

### <a name="module_production_failover_virtual_networks"></a> [production\_failover\_virtual\_networks](#module\_production\_failover\_virtual\_networks)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: ~> 0.7.0

### <a name="module_production_policy_links"></a> [production\_policy\_links](#module\_production\_policy\_links)

Source: ../res-enterprise-policy-link

Version:

### <a name="module_production_primary_virtual_networks"></a> [production\_primary\_virtual\_networks](#module\_production\_primary\_virtual\_networks)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: ~> 0.7.0

### <a name="module_production_resource_groups"></a> [production\_resource\_groups](#module\_production\_resource\_groups)

Source: Azure/avm-res-resources-resourcegroup/azurerm

Version: ~> 0.1.0

## Authentication

This configuration requires authentication to Microsoft Power Platform and Azure:

- **OIDC Authentication**: Uses GitHub Actions OIDC with Azure/Entra ID
- **Required Permissions**: Power Platform Service Admin role + Azure Contributor
- **State Backend**: Azure Storage with OIDC authentication

### Service Principal Permission Requirements

**Power Platform Permissions:**
- Power Platform Service Admin role for enterprise policy management
- Environment Admin role for policy linking to environments

**Azure Permissions:**
- Contributor role on target subscriptions for VNet deployment
- Network Contributor role for subnet delegation and network security groups
- Reader role on remote state storage for cross-pattern integration

## Data Collection

This configuration does not collect telemetry data. All data queried remains within your Power Platform tenant and Azure subscriptions, accessible only through your authenticated Terraform execution environment.

## ⚠️ AVM Compliance

### Provider Exception

This configuration uses the `microsoft/power-platform` provider alongside `azurerm`, creating a partial exception to AVM TFFR3 requirements since Power Platform enterprise policies are not available through approved Azure providers (`azurerm`/`azapi`).

**Exception Documentation**: [Power Platform Provider Exception](../../docs/explanations/power-platform-provider-exception.md)

### Complementary Details

- **Anti-Corruption Layer**: Implements TFFR2 compliance by providing discrete outputs and hiding internal implementation details
- **Security-First**: Sensitive data properly marked and segregated in outputs
- **AVM-Inspired**: Follows AVM patterns and standards where technically feasible
- **Pattern Orchestration**: Orchestrates multiple resource modules rather than creating resources directly

## Dynamic IP Allocation Technical Details

### Automatic Calculation Logic

This pattern uses Terraform's `cidrsubnet()` function to automatically calculate per-environment IP ranges:

```hcl
# Base /12 gets subdivided into /16 environments
primary_vnet_address_space = cidrsubnet(
  var.network_configuration.primary.vnet_address_space_base,
  4,    # Expand /12 to /16 (4 additional bits)
  idx   # Environment index (0, 1, 2, 3...)
)
```

### Capacity Planning

**Base Address Space Options:**
- `/12` supports up to 16 environments (65,536 IPs each)
- `/11` supports up to 32 environments (65,536 IPs each)  
- `/10` supports up to 64 environments (65,536 IPs each)

**Per-Environment Allocation:**
- Each environment receives a dedicated `/16` (65,536 IPs)
- Power Platform subnet: `/24` (256 IPs) at offset 1
- Private endpoint subnet: `/24` (256 IPs) at offset 2
- Remaining capacity: ~65,000 IPs for future expansion

### Mathematical Guarantees

**Non-Overlapping IP Ranges:**
- Primary region: `10.100.0.0/12` → Environments get `10.100.0.0/16`, `10.101.0.0/16`, etc.
- Failover region: `10.112.0.0/12` → Environments get `10.112.0.0/16`, `10.113.0.0/16`, etc.
- Zero possibility of IP conflicts between environments or regions

**Validation Logic:**
- Base address spaces must be `/12` or larger
- Calculated ranges are validated for proper CIDR notation
- Subnet offsets are validated to ensure subnets fit within parent `/16`
- Environment count is automatically detected from ptn-environment-group state

## Troubleshooting

### Common Issues

**Authentication Failures**
- Verify service principal has both Power Platform Service Admin and Azure Contributor roles
- Confirm OIDC configuration in GitHub repository secrets for both platforms
- Check tenant ID and client ID configuration for cross-platform authentication

**Permission Errors**
- Ensure service principal is not blocked by conditional access policies
- Verify admin permissions for enterprise policy and VNet management
- Check for tenant-level restrictions on automation across Azure and Power Platform

**Remote State Access Issues**
- Verify workspace\_name matches exactly with ptn-environment-group deployment
- Confirm remote state storage account permissions and network access
- Check that ptn-environment-group has completed deployment before running this pattern

### Network Configuration Issues

**Dynamic IP Allocation Conflicts**
- Verify base address spaces (`/12`) don't overlap between primary and failover regions
- Ensure base address spaces provide sufficient capacity for your environment count
- Check that calculated per-environment `/16` ranges don't conflict with existing Azure networks
- Validate subnet allocation offsets allow proper subnets within each environment's `/16`

**Environment Count Scaling Issues**
- Confirm environment count in ptn-environment-group matches your network capacity planning
- Verify base address space is `/12` or larger to support multiple environments (max 16 with `/12`)
- Check that all environments get unique `/16` allocations without overlap
- Ensure existing Azure networks don't conflict with calculated IP ranges

**IP Address Range Planning**
- Use network calculators to verify your base address spaces provide sufficient capacity
- Test IP allocation logic with different environment counts before deployment
- Consider future growth when selecting base address space size
- Document IP allocation strategy for operational teams

**Enterprise Policy Deployment**
- Confirm environments are in correct state for policy application (not suspended/disabled)
- Verify Power Platform environments exist before applying network injection policies
- Check for existing enterprise policies that might conflict with network injection
- Ensure each environment gets properly linked to its dedicated VNet resources

## Additional Links

- [Power Platform Enterprise Policies Documentation](https://docs.microsoft.com/en-us/power-platform/admin/enterprise-policies)
- [Azure VNet Integration for Power Platform](https://docs.microsoft.com/en-us/power-platform/admin/vnet-support)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)
<!-- END_TF_DOCS -->