# 🚀 Power Platform Governance with Terraform

<div align="center">

![Power Platform + Terraform](https://img.shields.io/badge/Power%20Platform-❤️-742774?style=for-the-badge&logo=microsoft)
![Infrastructure as Code](https://img.shields.io/badge/IaC-Terraform-623CE4?style=for-the-badge&logo=terraform)
![PPCC25](https://img.shields.io/badge/PPCC-2025-blue?style=for-the-badge)
![Archived](https://img.shields.io/badge/Status-Archived-red?style=for-the-badge)

**Transform your Power Platform governance from ClickOps to Infrastructure as Code**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

> [!WARNING]
> **This repository is archived and no longer actively maintained.**
>
> It was created as demonstration material for the session [**"Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"**](https://github.com/rpothin/Presentations/tree/main/20251029_PowerPlatformCommunityConference#enhancing-power-platform-governance-through-terraform-embracing-infrastructure-as-code) presented at **Power Platform Community Conference 2025** by [Raphael Pothin](https://github.com/rpothin).
>
> The code and documentation are preserved here as a **read-only reference**. No issues, pull requests, or discussions will be monitored. For questions or feedback, please reach out to [Raphael Pothin](https://github.com/rpothin) directly.

---

## 🎯 About

This repository demonstrates how **Infrastructure as Code (IaC)** with Terraform can transform Power Platform governance, addressing common challenges faced by platform administrators:

| Traditional ClickOps | Infrastructure as Code       |
| -------------------- | ---------------------------- |
| 🖱️ Manual clicks      | 📝 Declarative configuration |
| 🔍 No audit trail     | 📊 Complete version history  |
| 😰 Error-prone        | ✅ Validated and tested       |
| 🐌 Slow to scale      | 🚀 Instantly replicable       |
| 🔧 Hard to maintain   | 🔄 Self-documenting           |

## 📁 Project Structure

```plaintext
🏗️ ppcc25-terraform-power-platform-governance/
├── 📦 configurations/     # Ready-to-deploy Terraform configurations
│   ├── ptn-*             # Complete implementation patterns
│   ├── res-*             # Individual resource configurations
│   └── utl-*             # Utility configurations (exports, generation)
├── 📚 docs/              # Complete documentation (tutorials, guides, references)
├── 🤖 .github/           # GitHub workflows and automation
├── 🎬 .demo/             # Demo scripts and assets used during the conference session
├── 🛠️ scripts/           # Setup, cleanup, and utility scripts
└── 🔧 .devcontainer/     # Development container configuration
```

## 🎯 What Does This Demonstrate?

### 🛡️ Data Loss Prevention (DLP) Policies

Control which connectors can be used together to prevent data leakage.

**Example**: Finance department policy restricting data flow between SharePoint and external services.

### 🌍 Environment Provisioning

Create and configure Power Platform environments consistently.

**Example**: Dev/Test/Prod environment group with standardized settings.

### 🔗 Azure Integration

Extend environments with Azure VNet for secure hybrid connectivity.

**Example**: Private connectivity between Power Platform and Azure SQL using enterprise policies, zero-trust NSGs, and private DNS zones.

---

### Configuration Catalog

| Configuration              | Purpose                                     | Complexity      |
| -------------------------- | ------------------------------------------- | --------------- |
| `utl-export-connectors`    | Export connector list from tenant           | ⭐ Simple        |
| `utl-export-dlp-policies`  | Export existing DLP policies                | ⭐ Simple        |
| `utl-generate-dlp-tfvars`  | Generate tfvars from exported policies      | ⭐ Simple        |
| `res-dlp-policy`           | Create/update DLP policies                  | ⭐⭐ Easy         |
| `ptn-environment-group`    | Provision environment group (Dev/Test/Prod) | ⭐⭐⭐⭐ Advanced   |
| `ptn-azure-vnet-extension` | Add Azure VNet integration                  | ⭐⭐⭐⭐ Advanced   |

## 🔬 Key Technical Details

- **Terraform**: >= 1.5.0 required
- **Authentication**: OIDC (zero stored credentials)
- **State Management**: Azure Storage backend
- **Provider**: `microsoft/power-platform` ~> 3.8
- **Azure Infrastructure**: Built on [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/)
- **Naming**: Cloud Adoption Framework (CAF) conventions

## 📖 Documentation

The `docs/` folder contains full Diátaxis-structured documentation preserved for reference:

| Section | Content |
|---------|---------|
| [📚 Documentation Home](docs/README.md) | Starting point and navigation |
| [🎓 Tutorials](docs/tutorials/) | Step-by-step walkthroughs (Getting Started, DLP Policies, Environment Groups) |
| [🔧 How-to Guides](docs/guides/) | Task-specific instructions (setup, DLP management, ClickOps migration, troubleshooting) |
| [📖 Reference](docs/reference/) | Configuration catalog, module reference, common patterns |
| [💡 Explanations](docs/explanations/) | Architecture decisions, why IaC, known limitations |

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

### Author

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
  </tr>
</table>
</div>

### Inspiration

- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Power Platform Terraform Provider](https://registry.terraform.io/providers/microsoft/power-platform/latest/docs)

---

<div align="center">

**Made with ❤️ for the Power Platform Community**

*Presented at Power Platform Community Conference 2025*

[⬆ Back to top](#-power-platform-governance-with-terraform)

</div>
