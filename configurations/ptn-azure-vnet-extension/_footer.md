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

### Azure Verified Module Integration

This configuration leverages multiple Azure Verified Module (AVM) modules for Azure infrastructure:

- **Azure/avm-res-resources-resourcegroup** (~> 0.2.0): Resource group orchestration with enterprise tagging
- **Azure/avm-res-network-virtualnetwork** (~> 0.7.2): VNet deployment with subnet delegation and private endpoint support
- **Azure/avm-res-network-networksecuritygroup** (~> 0.5.0): Unified NSG architecture with zero-trust security rules
- **Azure/avm-res-network-privatednszone** (~> 0.1.0): Private DNS zones with automatic VNet linking

**AVM Compliance Status**: ✅ **Fully Compliant** for all Azure infrastructure components

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

**Zero-Trust Network Security Group Issues**
- Validate NSG rule deployment using valid Azure service tags (e.g., 'PowerPlatformInfra' not 'PowerPlatform')
- Verify unified NSG architecture serves both PowerPlatform and PrivateEndpoint subnets correctly
- Check NSG-subnet associations for both subnet types in each environment
- Confirm zero-trust rules allow VNet communication while blocking unnecessary external access
- Review security rule priorities (100-130 for allow rules, 4000 for deny rules)

**Private DNS Zone Deployment Issues**
- Ensure `private_dns_zones` variable contains at least one DNS zone (empty set `[]` prevents deployment)
- Verify DNS zone names follow proper Azure private DNS zone naming conventions
- Check VNet links are created for both primary and failover VNets
- Validate DNS zones deploy to correct resource groups via `parent_id` references
- Confirm setproduct() creates proper combinations of environments and DNS zones

**Subnet Naming Consistency Issues**
- Verify centralized naming patterns use consistent lowercase conversion
- Check that `private_endpoint_subnet_name` matches PowerPlatform subnet naming conventions
- Ensure CAF naming compliance across all subnet types
- Validate environment suffix processing removes spaces and special characters correctly

**Environment Count Scaling Issues**
- Confirm environment count in ptn-environment-group matches your network capacity planning
- Verify base address space is `/12` or larger to support multiple environments (max 16 with `/12`)
- Check that all environments get unique `/16` allocations without overlap
- Ensure existing Azure networks don't conflict with calculated IP ranges

### Zero-Trust Networking and Resource Conflict Resolution

**NSG Rule Validation Errors**
- **Invalid Service Tags**: Replace non-existent service tags (e.g., 'PowerPlatform' → 'PowerPlatformInfra')
- **Priority Conflicts**: Ensure rule priorities don't conflict with existing NSG rules
- **Address Prefix Issues**: Validate CIDR notation in security rules
- **Port Range Validation**: Confirm port ranges follow Azure NSG requirements

**Subnet Resource Conflicts**
- **IP Range Overlaps**: Use `NetcfgSubnetRangesOverlap` error resolution by manual subnet deletion
- **Delegation Conflicts**: Verify Power Platform delegation doesn't conflict with existing delegations
- **NSG Association Errors**: Remove existing NSG associations before applying unified NSG architecture
- **Partial Deployment State**: Use `terraform refresh` and manual cleanup for orphaned resources

**Private DNS Zone Connectivity Issues**
- **Empty DNS Zone Set**: Add at least one DNS zone to `private_dns_zones` variable in tfvars
- **VNet Linking Failures**: Verify VNets exist before DNS zone deployment using proper `depends_on`
- **Registration vs Resolution**: Ensure `registration_enabled = false` for private endpoint scenarios
- **Cross-Region DNS**: Confirm DNS zones link to both primary and failover VNets for comprehensive resolution

**Resolution Commands for Common Issues**
```bash
# Fix subnet conflicts by manual deletion
az network vnet subnet delete --name <conflicting-subnet> --vnet-name <vnet-name> --resource-group <rg-name>

# Sync Terraform state after manual fixes
terraform refresh

# Validate NSG rules before apply
terraform plan | grep -A 10 -B 5 "azurerm_network_security_group"

# Check DNS zone deployment status
az network private-dns zone list --resource-group <rg-name> --output table
```

**Enterprise Policy Deployment**
- Confirm environments are in correct state for policy application (not suspended/disabled)
- Verify Power Platform environments exist before applying network injection policies
- Check for existing enterprise policies that might conflict with network injection
- Ensure each environment gets properly linked to its dedicated VNet resources
- **Power Platform Region Alignment**: Ensure Azure regions map to correct Power Platform regions (Canada Central/Canada East → "canada")

### Performance and Timing Considerations

**Deployment Duration (Based on Validated Experience)**
- **Complete Pattern Deployment**: 10-15 minutes end-to-end (increased from 8-12 due to NSG and DNS zones)
- **Azure Infrastructure Phase**: 6-8 minutes (Resource Groups + VNets + NSGs)
- **Private DNS Zone Phase**: 2-3 minutes (DNS zones + VNet linking)
- **Enterprise Policy Phase**: 3-5 minutes (Policy creation + linking)
- **Remote State Reading**: ~30 seconds (including validation)

**Component-Specific Deployment Times**
- **Unified NSGs**: ~1-2 minutes per environment (creation + subnet associations)
- **Private DNS Zones**: ~30 seconds per zone per environment
- **VNet Linking**: ~15 seconds per DNS zone per VNet (4 links per environment)
- **Security Rule Application**: ~10 seconds per NSG (5 rules each)

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