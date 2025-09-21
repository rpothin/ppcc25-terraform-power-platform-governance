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
- Verify `paired_tfvars_file` matches exactly with ptn-environment-group deployment
- Confirm remote state storage account permissions and network access
- Check that ptn-environment-group has completed deployment before running this pattern
- Validate backend configuration includes all required Azure Storage parameters

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
- **Power Platform Region Alignment**: Ensure Azure regions map to correct Power Platform regions (Canada Central/Canada East → "canada")

### Performance and Timing Considerations

**Deployment Duration (Based on Validated Experience)**
- **Complete Pattern Deployment**: 8-12 minutes end-to-end
- **Azure Infrastructure Phase**: 4-6 minutes (Resource Groups + VNets)
- **Enterprise Policy Phase**: 3-5 minutes (Policy creation + linking)
- **Remote State Reading**: ~30 seconds (including validation)

**Environment Group Prerequisites**
- **Timing Window**: Allow 2-5 minutes after `ptn-environment-group` completion before running VNet extension
- **Race Condition Management**: Environment group assignment automatically converts environments to managed status asynchronously
- **State File Availability**: Verify `ptn-environment-group-{paired_tfvars_file}.tfstate` exists before deployment

**Concurrent Deployment Limitations**
- **Sequential Pattern Deployment**: Deploy `ptn-environment-group` first, then `ptn-azure-vnet-extension`
- **Regional Deployment Order**: Primary and failover regions deploy in parallel for efficiency
- **Subscription Isolation**: Production and non-production subscriptions deploy concurrently

### Capacity and Scaling Performance

**Environment Count Impact on Deployment Time**
- **2-3 Environments**: 8-10 minutes total deployment
- **4-6 Environments**: 10-12 minutes total deployment  
- **7+ Environments**: Add ~1 minute per additional environment

**IP Allocation Performance**
- **Dynamic Calculation**: Instantaneous during planning phase
- **Validation Overhead**: ~5-10 seconds per environment for IP range validation
- **Zero Network Scanning**: No existing network discovery required (mathematical allocation)

## Additional Links

- [Power Platform Enterprise Policies Documentation](https://docs.microsoft.com/en-us/power-platform/admin/enterprise-policies)
- [Azure VNet Integration for Power Platform](https://docs.microsoft.com/en-us/power-platform/admin/vnet-support)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)
- [AVM Terraform Specifications](https://azure.github.io/Azure-Verified-Modules/specs/tf/)