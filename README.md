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

**New to this?** → Start with our **[📚 Complete Documentation](docs/README.md)** for detailed guidance.

### Prerequisites

- Power Platform admin access
- Azure subscription  
- GitHub account

> **💡 Tip**: Get free access through the [Microsoft 365 Developer Program](https://developer.microsoft.com/microsoft-365/dev-program). Development tools are validated automatically during setup.
>
> **📖 Need detailed prerequisites?** See [Getting Started Tutorial](docs/tutorials/01-getting-started.md#prerequisites)

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

**📖 What's Next?** Follow the [Getting Started Tutorial](docs/tutorials/01-getting-started.md) for your first deployment!

## 📁 Project Structure

```plaintext
🏗️ ppcc25-terraform-power-platform-governance/
├── 📦 configurations/     # Ready-to-deploy Terraform configurations
│   ├── ptn-*             # Complete implementation patterns
│   ├── res-*             # Individual resource configurations
│   └── utl-*             # Utility configurations (exports, generation)
├── 📚 docs/              # Complete documentation (tutorials, guides, references)
├── 🤖 .github/           # GitHub workflows and automation
├── 🛠️ scripts/           # Setup, cleanup, and utility scripts
└── 🔧 .devcontainer/     # Development container configuration
```

**📖 Complete structure details**: See [Configuration Catalog](docs/reference/configuration-catalog.md)

## 🎯 What Can You Build?

### 🛡️ Data Loss Prevention (DLP) Policies
Control which connectors can be used together to prevent data leakage.

**Example**: Finance department policy restricting data flow between SharePoint and external services.

### 🌍 Environment Provisioning
Create and configure Power Platform environments consistently.

**Example**: Dev/Test/Prod environment group with standardized settings.

### 🔗 Azure Integration
Extend environments with Azure VNet for secure hybrid connectivity.

**Example**: Private connectivity between Power Platform and Azure SQL.

---

**📖 See complete examples**: 
- [DLP Policy Management Guide](docs/guides/dlp-policy-management.md)
- [Configuration Catalog](docs/reference/configuration-catalog.md)
- [Common Patterns](docs/reference/common-patterns.md)

## 🔬 Key Technical Details

- **Terraform**: >= 1.5.0 required
- **Authentication**: OIDC (zero stored credentials)
- **State Management**: Azure Storage backend
- **Provider**: microsoft/power-platform ~> 3.8

**🔗 Complete technical reference**: [Architecture Decisions](docs/explanations/architecture-decisions.md)

---

## 📖 Documentation & Learning

### 🎯 Start Here
**New to this project?** Our documentation follows a progressive learning approach:

1. **📚 [Documentation Home](docs/README.md)** - Your starting point for all documentation
2. **🎓 [Tutorials](docs/tutorials/)** - Step-by-step learning (beginner-friendly)
3. **🔧 [How-to Guides](docs/guides/)** - Task-specific instructions (for when you're working)
4. **📖 [Reference](docs/reference/)** - Complete configuration details (for lookups)
5. **💡 [Explanations](docs/explanations/)** - Deep dives into concepts (for understanding)

### 🚀 Quick Paths

| Your Goal | Recommended Path |
|-----------|------------------|
| **First time setup** | [Getting Started Tutorial](docs/tutorials/01-getting-started.md) → [DLP Policies Tutorial](docs/tutorials/02-first-dlp-policy.md) |
| **Deploy DLP policies** | [DLP Policies Tutorial](docs/tutorials/02-first-dlp-policy.md) → [DLP Management Guide](docs/guides/dlp-policy-management.md) |
| **Provision environments** | [Environment Groups Tutorial](docs/tutorials/03-environment-management.md) → [Configuration Catalog](docs/reference/configuration-catalog.md) |
| **Migrate from ClickOps** | [Why IaC?](docs/explanations/why-infrastructure-as-code.md) → [Migration Guide](docs/guides/migrate-from-clickops.md) |
| **Troubleshoot issues** | [Troubleshooting Guide](docs/guides/troubleshooting.md) → [Known Limitations](docs/explanations/known-limitations-and-platform-constraints.md) |

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