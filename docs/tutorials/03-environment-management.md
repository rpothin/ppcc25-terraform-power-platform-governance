# Tutorial: Environment Groups and Azure Integration

![Tutorial](https://img.shields.io/badge/Diataxis-Tutorial-blue?style=for-the-badge&logo=book)

**Estimated Time**: 40 minutes  
**Prerequisites**: Complete [Working with DLP Policies Tutorial](02-first-dlp-policy.md)  
**You'll Learn**: How to provision complete environment groups and extend them with Azure networking

---

## 🎯 What You'll Build

By the end of this tutorial, you will have:
- ✅ A complete environment group with Dev, Test, and Prod environments
- ✅ Azure VNet integration for secure connectivity
- ✅ Private DNS zones for Azure services
- ✅ Understanding of hybrid Power Platform + Azure patterns

## 🎓 Learning Objectives

This tutorial teaches you:
- How to provision environment groups with templates
- How to create multiple environments from a single configuration
- How to extend Power Platform with Azure networking
- How to implement secure hybrid architectures

---

## 📚 Background: Environment Groups

**Environment Groups** provide organizational structure for related environments:

- **Grouping**: Logically organize environments by project, team, or workload
- **Templates**: Consistent patterns for Dev/Test/Prod environments
- **Lifecycle**: Manage entire groups as a unit
- **Security**: Apply group-level security controls

**Pattern Modules**: The `ptn-environment-group` configuration creates:
1. Environment group container
2. Multiple environments (Dev, Test, Prod)
3. Dataverse databases for each environment
4. Application admin assignments

💡 **Key Concept**: Pattern modules orchestrate multiple resource modules to create complete solutions.

---

## Part 1: Provision an Environment Group

Let's create a complete workspace with Dev, Test, and Production environments.

### Step 1: Create the Configuration

1. **Navigate to the pattern configuration**:
   ```bash
   cd configurations/ptn-environment-group/tfvars
   ```

2. **Copy the template**:
   ```bash
   cp template.tfvars my-workspace.tfvars
   ```

3. **Edit the configuration**:
   ```bash
   nano my-workspace.tfvars
   ```

4. **Configure your workspace**:
   ```hcl
   # ═══════════════════════════════════════════════════════════════
   # My Learning Workspace - Environment Group
   # ═══════════════════════════════════════════════════════════════
   
   # Environment Group Configuration
   name        = "MyLearningWorkspace"
   description = "Learning environment group for Terraform demonstrations"
   
   # Region Configuration
   region = "unitedstates"
   
   # Security: Restrict to a specific Azure AD group (optional)
   # security_group_id = "YOUR-AZURE-AD-GROUP-GUID"
   
   # Environment Template Selection
   # Options: "standard-three-tier", "minimal-dev-only", "comprehensive-five-tier"
   environment_template = "standard-three-tier"
   
   # Dataverse Configuration for all environments
   dataverse_language_code = 1033  # English (US)
   dataverse_currency_code = "USD"
   
   # Application Admin Configuration (optional)
   # application_registration_id = "YOUR-APP-REGISTRATION-GUID"
   ```

5. **Save the file** (Ctrl+X, Y, Enter)

### Step 2: Understand the Template System

1. **View the template logic**:
   ```bash
   cat configurations/ptn-environment-group/locals.tf
   ```

Key concepts:
- **Templates**: Pre-defined patterns for common scenarios
- **Dynamic generation**: Environments created from template definitions
- **Naming conventions**: Consistent naming across environments

Templates available:
- `standard-three-tier`: Dev, Test, Prod (default)
- `minimal-dev-only`: Single development environment
- `comprehensive-five-tier`: Dev, Test, UAT, Staging, Prod

### Step 3: Deploy the Environment Group

1. **Commit your configuration**:
   ```bash
   git add configurations/ptn-environment-group/tfvars/my-workspace.tfvars
   git commit -m "feat: add learning workspace environment group"
   git push
   ```

2. **Deploy via GitHub Actions**:
   ```bash
   gh workflow run terraform-plan-apply.yml \
     -f configuration=ptn-environment-group \
     -f tfvars_file=my-workspace \
     -f apply=true \
     -f extract_outputs=false
   ```

3. **Monitor the deployment**:
   ```bash
   # This will take 15-20 minutes due to Dataverse provisioning
   gh run list --workflow=terraform-plan-apply.yml --limit 1
   ```

💡 **What's happening?**:
- Creating environment group container
- Provisioning 3 environments in parallel (Dev, Test, Prod)
- Setting up Dataverse databases (takes the most time)
- Configuring environment settings
- Assigning application admins (if configured)

### Step 4: Verify Your Environment Group

1. **Once deployment completes, check the output**:
   ```bash
   git pull
   ```

2. **View in Power Platform Admin Center**:
   - Go to https://admin.powerplatform.microsoft.com/manage/environmentGroups
   - You should see "MyLearningWorkspace"
   - Click it to see all 3 environments

3. **Verify Dataverse**:
   - Go to https://admin.powerplatform.microsoft.com/manage/environments
   - Each environment should show Dataverse status as "Ready"

💡 **Success Check**: You have a complete workspace with 3 environments, each with Dataverse, ready for development!

---

## Part 2: Azure VNet Extension

Now let's extend your environment group with Azure networking for secure hybrid scenarios.

### Step 1: Understand Azure VNet Integration

**Why Azure Networking?**
- **Private connectivity**: Secure communication between Power Platform and Azure services
- **Data residency**: Control data flow and storage locations
- **Hybrid scenarios**: Connect on-premises systems through Azure
- **Compliance**: Meet regulatory requirements for network isolation

**What gets created?**
- Azure Virtual Network (VNet) with subnets
- Private DNS zones for Azure services
- VNet links to environment group
- Network security configurations

### Step 2: Create VNet Configuration

1. **Navigate to the VNet extension configuration**:
   ```bash
   cd /workspaces/ppcc25-terraform-power-platform-governance/configurations/ptn-azure-vnet-extension/tfvars
   ```

2. **Copy the template**:
   ```bash
   cp template.tfvars my-workspace-vnet.tfvars
   ```

3. **Edit the configuration**:
   ```bash
   nano my-workspace-vnet.tfvars
   ```

4. **Configure your Azure networking**:
   ```hcl
   # ═══════════════════════════════════════════════════════════════
   # Azure VNet Extension for MyLearningWorkspace
   # ═══════════════════════════════════════════════════════════════
   
   # Link to your environment group
   environment_group_name = "MyLearningWorkspace"
   
   # Azure Configuration
   location            = "eastus"        # Must match Power Platform region mapping
   resource_group_name = "rg-powerplatform-myworkspace"
   
   # Virtual Network Configuration
   vnet_name          = "vnet-powerplatform-myworkspace"
   vnet_address_space = ["10.0.0.0/16"]
   
   # Subnet Configuration
   subnets = {
     power-platform = {
       address_prefixes = ["10.0.1.0/24"]
       delegation       = "Microsoft.PowerPlatform/enterprisePolicies"
     }
     azure-services = {
       address_prefixes = ["10.0.2.0/24"]
       service_endpoints = [
         "Microsoft.Storage",
         "Microsoft.KeyVault",
         "Microsoft.Sql"
       ]
     }
   }
   
   # Private DNS Zones (recommended Azure services)
   private_dns_zones = [
     "privatelink.blob.core.windows.net",
     "privatelink.vaultcore.azure.net",
     "privatelink.database.windows.net"
   ]
   
   # Tags for Azure resources
   tags = {
     Environment = "Learning"
     Project     = "PPCC25-Governance"
     ManagedBy   = "Terraform"
     Owner       = "YourName"
   }
   ```

5. **Save the file** (Ctrl+X, Y, Enter)

💡 **Important**: The `location` must align with your Power Platform region. See the region mapping in the configuration README.

### Step 3: Deploy Azure VNet Extension

1. **Commit your configuration**:
   ```bash
   git add configurations/ptn-azure-vnet-extension/tfvars/my-workspace-vnet.tfvars
   git commit -m "feat: add Azure VNet extension for learning workspace"
   git push
   ```

2. **Deploy via GitHub Actions**:
   ```bash
   gh workflow run terraform-plan-apply.yml \
     -f configuration=ptn-azure-vnet-extension \
     -f tfvars_file=my-workspace-vnet \
     -f apply=true \
     -f extract_outputs=false
   ```

3. **Monitor the deployment**:
   ```bash
   # This will take 5-10 minutes
   gh run watch
   ```

💡 **What's happening?**:
- Creating Azure Resource Group
- Provisioning Virtual Network and subnets
- Setting up Private DNS zones
- Linking VNet to environment group
- Configuring subnet delegation for Power Platform

### Step 4: Verify Azure Integration

1. **Check Azure Portal**:
   - Go to https://portal.azure.com
   - Navigate to Resource Groups → `rg-powerplatform-myworkspace`
   - You should see:
     - Virtual Network
     - Private DNS Zones (3)
     - DNS Zone Links

2. **Verify Power Platform connection**:
   ```bash
   # Pull the latest outputs
   git pull
   
   # View the VNet integration details
   cat configurations/ptn-azure-vnet-extension/tfvars/my-workspace-vnet.outputs.json | jq
   ```

3. **Check in Power Platform Admin Center**:
   - Go to your environment group
   - Navigate to Azure → Virtual Networks
   - You should see your VNet linked

💡 **Success Check**: Your environment group now has secure Azure connectivity!

---

## Part 3: Test the Complete Setup

Let's verify everything works together.

### Step 1: Deploy a Test App

1. **Create a simple Power App** in your Dev environment:
   - Go to https://make.powerapps.com
   - Select "Dev - My Learning Environment"
   - Create a Canvas app
   - Add a connection to an Azure service (like Azure Blob Storage)

2. **Test the connection**:
   - The connection should work through the private VNet
   - No public internet connectivity required!

### Step 2: Verify Network Isolation

1. **Check Network Security Group (NSG) rules** in Azure Portal:
   ```
   Resource Group → Virtual Network → Subnets → power-platform → NSG
   ```

2. **Review DNS resolution**:
   - Private endpoints should resolve to private IPs
   - No public IP exposure for Azure services

### Step 3: Review Deployment Outputs

1. **View all terraform outputs**:
   ```bash
   # Environment Group outputs
   cat configurations/ptn-environment-group/tfvars/my-workspace.outputs.json | jq
   
   # VNet Extension outputs
   cat configurations/ptn-azure-vnet-extension/tfvars/my-workspace-vnet.outputs.json | jq
   ```

2. **Key outputs to note**:
   - Environment IDs and URLs
   - VNet ID and subnet IDs
   - DNS zone resource IDs
   - Environment group resource ID

---

## 🎉 Congratulations!

You've successfully completed the Environment Groups and Azure Integration tutorial!

### What You've Accomplished

✅ **Environment Group Provisioning**:
- Created a complete workspace with Dev, Test, Prod environments
- Configured Dataverse databases for each environment
- Applied consistent naming and organization

✅ **Azure Integration**:
- Extended your environment group with Azure VNet
- Set up private connectivity for secure hybrid scenarios
- Configured Private DNS zones for Azure services
- Implemented network isolation and security

✅ **Pattern Understanding**:
- Learned how pattern modules orchestrate multiple resources
- Understood template-based environment provisioning
- Explored hybrid Power Platform + Azure architectures

### Real-World Applications

This pattern enables:
- **Enterprise deployments**: Secure, compliant multi-environment setups
- **Hybrid scenarios**: On-premises integration through Azure
- **Data sovereignty**: Control data residency and network flow
- **DevOps workflows**: Consistent environment provisioning

---

## 🔍 What You Learned

### Key Concepts

1. **Environment Groups**:
   - Logical organization of related environments
   - Template-based provisioning for consistency
   - Group-level security and lifecycle management

2. **Azure VNet Integration**:
   - Private connectivity between Power Platform and Azure
   - Network isolation and security boundaries
   - Private DNS for Azure service endpoints

3. **Pattern Modules**:
   - Orchestration of multiple resource modules
   - Reusable architecture patterns
   - Complete solution provisioning

4. **Hybrid Architecture**:
   - Combining Power Platform SaaS with Azure PaaS/IaaS
   - Secure connectivity patterns
   - Compliance and governance controls

---

## 📚 What's Next?

### Recommended Learning Path

1. **Apply DLP Policies** to your environment group:
   - Navigate to [DLP Policy Management Guide](../guides/dlp-policy-management.md)
   - Create environment-specific policies
   - Test policy enforcement

2. **Configure Environment Settings**:
   - Explore `res-environment-settings` configuration
   - Customize limits, features, and security
   - Understand available settings

3. **Set Up Application Admins**:
   - Review `res-environment-application-admin` configuration
   - Grant service principal access
   - Enable automated deployments

4. **Explore Advanced Patterns**:
   - Multi-region deployments
   - Cross-tenant scenarios
   - Complex networking topologies

### Additional Resources

- **How-to Guide**: [DLP Policy Management](../guides/dlp-policy-management.md)
- **Reference**: [Configuration Catalog](../reference/configuration-catalog.md)
- **Explanation**: [Architecture Decisions](../explanations/architecture-decisions.md)
- **Reference**: [Common Patterns](../reference/common-patterns.md)

---

## 🆘 Need Help?

### Common Issues

**Environment provisioning takes too long**:
- Dataverse provisioning typically takes 10-15 minutes per environment
- The workflow provisions environments in parallel when possible
- Check workflow logs for progress updates

**VNet linking fails**:
- Verify region alignment between Power Platform and Azure
- Check Azure subscription permissions
- Ensure subnet delegation is configured correctly

**Private DNS not resolving**:
- Verify DNS zone links are created
- Check VNet configuration
- Confirm private endpoints are deployed

### Getting Support

- Review [Troubleshooting Guide](../guides/troubleshooting.md)
- Check [Known Limitations](../explanations/known-limitations-and-platform-constraints.md)
- Search existing [GitHub Issues](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/issues)

---

## 🧹 Cleanup (Optional)

If you want to remove what you've created:

```bash
# Destroy VNet extension first (dependencies)
gh workflow run terraform-destroy.yml \
  -f configuration=ptn-azure-vnet-extension \
  -f tfvars_file=my-workspace-vnet

# Wait for completion, then destroy environment group
gh workflow run terraform-destroy.yml \
  -f configuration=ptn-environment-group \
  -f tfvars_file=my-workspace
```

⚠️ **Warning**: Destroying environment groups will delete all environments and their data. This action cannot be undone!

---

**Tutorial Complete** | [← Previous: DLP Policies](02-first-dlp-policy.md) | [Documentation Home](../README.md)
