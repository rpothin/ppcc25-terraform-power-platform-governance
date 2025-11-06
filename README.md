# 🚀 Power Platform Governance with Terraform

<div align="center">

![Power Platform + Terraform](https://img.shields.io/badge/Power%20Platform-❤️-742774?style=for-the-badge&logo=microsoft)
![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform-623CE4?style=for-the-badge&logo=terraform)
![PPCC25](https://img.shields.io/badge/PPCC-2025-blue?style=for-the-badge)

**Transform your Power Platform governance from ClickOps to Infrastructure as Code**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/rpothin/ppcc25-terraform-power-platform-governance?style=social)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/stargazers)

[📚 Documentation](docs/) • [🎯 Quick Start](#-quick-start) <!--• [🎬 Demo Video](#)-->

</div>

## 🎯 About

> [!NOTE]
> [**"Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"**](https://powerplatformconf.com/#!/session/Enhancing%20Power%20Platform%20Governance%20Through%20Terraform:%20Embracing%20Infrastructure%20as%20Code/7663)
> *Presented at Power Platform Community Conference 2025 by [Raphael Pothin](https://github.com/rpothin)*

### The Problem

Power Platform administrators face critical challenges:
- **Manual Configuration Drift** - ClickOps leads to inconsistent environments
- **Audit Trail Gaps** - No version history for governance changes  
- **Scale Limitations** - Manual processes don't scale with enterprise growth
- **Recovery Complexity** - No easy rollback when things go wrong

### The Solution

This repository demonstrates how **Infrastructure as Code (IaC)** transforms Power Platform governance and can provide the following key benefits:

| Traditional ClickOps | Infrastructure as Code      |
| -------------------- | --------------------------- |
| 🖱️ Manual clicks      | 📝 Declarative configuration |
| 🔍 No audit trail     | 📊 Complete version history  |
| 😰 Error-prone        | ✅ Validated and tested      |
| 🐌 Slow to scale      | 🚀 Instantly replicable      |
| 🔧 Hard to maintain   | 🔄 Self-documenting          |

## 🚀 Quick Start

### Prerequisites

<details>
<summary>Click to expand prerequisites</summary>

- [ ] **Power Platform** admin access ([Join the Microsoft 365 Developer Program](https://developer.microsoft.com/en-us/microsoft-365/dev-program) → [Try Power Platform for free](https://www.microsoft.com/en-us/power-platform/products/power-apps/free))
- [ ] **Azure subscription** ([Free trial available](https://azure.microsoft.com/free))
- [ ] **GitHub account** ([Sign up free](https://github.com/signup))

> **Note**: Development tools (Terraform, Azure CLI, GitHub CLI) are validated automatically during setup.

</details>

### 30-Second Setup

```bash
# 1️⃣ Clone and configure
git clone https://github.com/rpothin/ppcc25-terraform-power-platform-governance.git
cd ppcc25-terraform-power-platform-governance
cp config.env.example config.env

# 2️⃣ Edit config (only 2 required values!)
nano config.env  # Set GITHUB_OWNER and GITHUB_REPO

# 3️⃣ Run automated setup
./setup.sh
```

**That's it!** 🎉 The setup script handles:
- Azure service principal creation with OIDC
- Terraform backend storage configuration
- GitHub secrets configuration
- Initial workspace setup

## 📁 Project Structure

```plaintext
🏗️ ppcc25-terraform-power-platform-governance/
│
├── 📦 configurations/                  # Ready-to-deploy Terraform configurations
│   ├── ptn-azure-vnet-extension/      # Azure VNet extension pattern
│   ├── ptn-environment-group/         # Environment grouping pattern
│   ├── res-dlp-policy/                # Data Loss Prevention policies
│   ├── res-enterprise-policy/         # Enterprise policy resources
│   ├── res-enterprise-policy-link/    # Enterprise policy linking
│   ├── res-environment/               # Environment creation
│   ├── res-environment-application-admin/ # Environment admin setup
│   ├── res-environment-group/         # Environment group resources
│   ├── res-environment-settings/      # Environment configuration
│   ├── utl-export-connectors/         # Export available connectors
│   ├── utl-export-dlp-policies/       # Export existing DLP policies
│   └── utl-generate-dlp-tfvars/       # Generate DLP tfvars from export
│
├── 🤖 .github/                         # GitHub automation
│   ├── workflows/                     # CI/CD pipelines
│   │   ├── terraform-plan-apply.yml   # Main deployment workflow
│   │   ├── terraform-test.yml         # Configuration validation
│   │   ├── terraform-docs.yml         # Documentation generation
│   │   └── ...                        # Additional workflows
│   ├── actions/                       # Custom GitHub Actions
│   │   ├── detect-terraform-changes/  # Change detection
│   │   ├── generate-workflow-metadata/ # Metadata generation
│   │   ├── jit-network-access/        # Just-in-time access
│   │   └── terraform-init-with-backend/ # Terraform initialization
│   ├── instructions/                  # AI agent guidelines
│   │   ├── baseline.instructions.md   # Core principles
│   │   ├── terraform-iac.instructions.md # Terraform standards
│   │   └── ...                        # Additional guidelines
│   └── prompts/                       # AI prompts for development
│
├── 📚 docs/                           # Documentation
│   ├── index.md                      # Documentation home
│   ├── explanations/                 # Concept explanations
│   ├── guides/                       # How-to guides
│   ├── references/                   # API/configuration references
│   └── troubleshooting/             # Common issues and solutions
│
├── 🛠️ scripts/                        # Automation scripts
│   ├── setup/                        # Initial setup scripts
│   │   └── setup-azure-backend.sh   # Azure backend configuration
│   ├── cleanup/                      # Resource cleanup scripts
│   ├── demo/                         # Demonstration utilities
│   └── utils/                        # Helper utilities
│
├── 🔧 .devcontainer/                  # Development container config
│   ├── devcontainer.json             # Container definition
│   └── post-create.sh                # Post-creation setup
│
├── 📝 Configuration Files
│   ├── config.env.example            # Environment configuration template
│   ├── CHANGELOG.md                  # Version history
│   ├── LICENSE                       # MIT License
│   └── .gitignore                    # Git ignore patterns
│
└── 🎭 .demo/                          # Demo scripts
    └──ppcc25-terraform-power-platform-governance.json
```

### Configuration Categories

The `configurations/` directory follows a naming convention inspired by Azure Verified Modules (AVM):

- **`ptn-*`** (Pattern): Complete implementation patterns combining multiple resources
- **`res-*`** (Resource): Individual resource configurations
- **`utl-*`** (Utility): Helper configurations for operations like exports and generation

## 🔧 Configuration Examples

### Example: Deploy DLP Policy for Finance

<details>
<summary>View complete example</summary>

#### Step 1: Copy the template

```bash
# Navigate to the DLP policy configuration
cd configurations/res-dlp-policy/tfvars/

# Create your finance policy from the template
cp template.tfvars finance.tfvars
```

#### Step 2: Edit the finance policy

```hcl
# finance.tfvars - Edit the following values:

# REQUIRED: Update the display name
display_name = "Finance Department Data Protection"

# OPTIONAL: Set to "Blocked" for maximum security (default if omitted)
default_connectors_classification = "Blocked"

# OPTIONAL: Apply to specific environments only
environment_type = "OnlyEnvironments"
environments = [
  "00000000-0000-0000-0000-000000000001",  # Replace with your Production environment ID
  "00000000-0000-0000-0000-000000000002"   # Replace with your Finance UAT environment ID
]

# BUSINESS CONNECTORS: Essential finance systems
# WHY: These connectors are required for financial operations and reporting
business_connectors = [
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sql"
    default_action_rule_behavior = "Allow"
    # Block dangerous SQL operations while allowing reads
    action_rules = [
      { action_id = "DeleteItem_V2", behavior = "Block" },
      { action_id = "ExecutePassThroughNativeQuery_V2", behavior = "Block" }
    ]
    # Only allow connections to finance databases
    endpoint_rules = [
      { endpoint = "finance-db.database.windows.net", behavior = "Allow", order = 1 },
      { endpoint = "*", behavior = "Block", order = 2 }
    ]
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    default_action_rule_behavior = "Allow"
    # Finance document library access only
    endpoint_rules = [
      { endpoint = "contoso.sharepoint.com/sites/finance", behavior = "Allow", order = 1 }
    ]
  },
  {
    id = "/providers/Microsoft.PowerApps/apis/shared_teams"
    default_action_rule_behavior = "Allow"
  }
]

# CUSTOM CONNECTORS: Restrict to internal APIs only
# WHY: Prevent data exfiltration through unapproved custom connectors
custom_connectors_patterns = [
  { order = 1, host_url_pattern = "*", data_group = "Blocked" }  # Block everything else
]
```

#### Step 3: Deploy via GitHub Actions

1. Go to **Actions** → **[Terraform Plan and Apply](../../actions/workflows/terraform-plan-apply.yml)**
2. Click **Run workflow**
3. Select:
   - Configuration: `res-dlp-policy`
   - Terraform vars file: `finance.tfvars`
   - Keep the `Apply` option unchecked (review first)
4. Review the plan output
5. If satisfied, run again with the `Apply` option checked to deploy

</details>

## 🔬 Technical Reference

### Terraform & Provider Versions

This repository follows strict version requirements to ensure consistency, reliability, and security across all Terraform configurations.

**Terraform Core**: All configurations require **Terraform >= 1.5.0** which provides:
- Enhanced validation capabilities for complex governance scenarios
- Improved lifecycle management for production workloads
- Better error messages and debugging support

**Provider Version Standards**:

| Provider                     | Version Constraint | Purpose                                                                     |
| ---------------------------- | ------------------ | --------------------------------------------------------------------------- |
| **microsoft/power-platform** | `~> 3.8`           | Power Platform resource management (DLP policies, environments, connectors) |
| **hashicorp/azurerm**        | `~> 4.0`           | Azure resources for VNet integration and enterprise policies                |
| **azure/azapi**              | `~> 2.6`           | Azure preview API access for enterprise policy resources                    |
| **hashicorp/null**           | `~> 3.0`           | Lifecycle management and validation triggers                                |
| **hashicorp/time**           | `~> 0.13`          | Time-based resource management                                              |
| **hashicorp/local**          | `~> 2.4`           | Local file generation for exports and utilities                             |

### Authentication & Security

All configurations use **OIDC (OpenID Connect)** authentication for enhanced security:

- **Zero stored credentials** - No client secrets in configuration or environment variables
- **Azure Storage backend** - Centralized state management with encryption at rest
- **Keyless authentication** - Leverages Azure AD workload identity federation

```hcl
# Standard backend configuration
terraform {
  backend "azurerm" {
    use_oidc = true
  }
}

# Standard provider configuration
provider "powerplatform" {
  use_oidc = true
}
```

### Module Architecture

Configurations follow Azure Verified Module (AVM) inspired patterns:

- **`ptn-*`** (Pattern modules): Root modules with backend/provider blocks for orchestration
- **`res-*`** (Resource modules): Child modules without backend/provider blocks (inherited from parent)
- **`utl-*`** (Utility modules): Standalone modules with backend blocks for independent operations

## 🤝 Contributing & Feedback

### 📣 We Value Your Feedback!

While this repository was specifically created as demonstration material for the **Power Platform Community Conference 2025** session and is not accepting code contributions, **your feedback is incredibly valuable**!

### How You Can Help

- **🐛 Report Issues** - Found a bug, security concern, or potential improvement? Please [open an issue](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/issues)
- **💡 Share Ideas** - Have suggestions for better approaches? We'd love to hear them!
- **❓ Ask Questions** - Something unclear? Use [Discussions](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions) to get clarification
- **⭐ Star the Repository** - Show your support and help others discover this resource
- **📢 Share Your Experience** - Used these patterns in your organization? Let us know how it went!

### Direct Feedback

For direct feedback, security concerns, or private discussions about this demonstration:
- 📧 Reach out to [Raphael Pothin](https://github.com/rpothin) directly
- 💼 Connect on [LinkedIn](https://www.linkedin.com/in/raphael-pothin-642bb657/)

### 🚀 What's Next?

**Coming Soon**: A community-driven initiative building on these concepts!

While this demonstration repository remains read-only, I'm working on launching a collaborative initiative that will:
- Welcome contributions
- Expand on the patterns demonstrated here
- Create a comprehensive library of configurations
- Build a supportive community around Power Platform IaC

Stay tuned for announcements! Follow this repository to be notified when the new initiative launches.

### Why This Approach?

This repository serves as **reference implementation** for the PPCC25 session. Keeping it stable ensures:
- ✅ Consistent experience for all session attendees
- ✅ Reliable demonstration material
- ✅ Clear educational narrative
- ✅ Preservation of the original presentation context

Your understanding and support are greatly appreciated! 🙏

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

### Contributors

<!-- ALL-CONTRIBUTORS-LIST:START -->
<div align="center">
<table>
  <tr>
    <td align="center">
      <a href="https://github.com/rpothin">
        <img src="https://github.com/rpothin.png" width="100px;" alt="Raphael Pothin"/>
        <br />
        <sub><b>Raphael Pothin</b></sub>
      </a>
      <br />
      💻 📖 🎨
    </td>
    <!-- Add more contributors here -->
  </tr>
</table>
<!-- ALL-CONTRIBUTORS-LIST:END -->
</div>

### Inspiration

This project was inspired by:
- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Power Platform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)

---

<div align="center">

**Made with ❤️ for the Power Platform Community**

[⬆ Back to top](#-power-platform-governance-with-terraform)

</div>