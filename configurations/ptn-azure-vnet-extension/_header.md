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
