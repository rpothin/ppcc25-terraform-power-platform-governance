# Power Platform Governance with Terraform - PPCC25

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4?logo=terraform)](https://www.terraform.io/)
[![Power Platform](https://img.shields.io/badge/Power%20Platform-742774?logo=microsoft)](https://powerplatform.microsoft.com/)

</div>

> **Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code**  
> *Presented at Power Platform Community Conference 2025 by Raphael Pothin*

## 🎯 Purpose

This repository contains the demonstration elements from the **"Enhancing Power Platform Governance Through Terraform: Embracing Infrastructure as Code"** session at the Power Platform Community Conference 2025. It serves as a **quickstart guide** for exploring how Terraform can be used to implement Power Platform governance and replace the traditional "ClickOps" approach.

The repository provides practical examples and reusable patterns to help organizations transition from manual Power Platform administration to automated, code-driven governance using Infrastructure as Code (IaC) principles.

## 🚀 What's Included

- **Terraform modules** for Power Platform governance components
- **Configuration examples** demonstrated in the PPCC25 session
- **Migration patterns** from ClickOps to Infrastructure as Code
- **Best practices** for enterprise Power Platform governance
- **Integration scenarios** with Azure

---

## 🚀 Workflow Status Dashboard

<div align="center">

| Workflow                    | Status                                                                                                                                                                                                                                                                      | Purpose                                 |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| **Terraform Documentation** | [![Terraform Docs](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-docs.yml/badge.svg)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-docs.yml)                       | Generate documentation                  |
| **Terraform Test**          | [![Terraform Test](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-test.yml/badge.svg)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-test.yml)                       | Validate configurations                 |
| **Terraform Output**        | [![Terraform Output](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-output.yml/badge.svg)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-output.yml)                 | Extract outputs from deployed resources |
| **Terraform Plan & Apply**  | [![Terraform Plan and Apply](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-plan-apply.yml/badge.svg)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-plan-apply.yml) | Deploy infrastructure changes           |
| **Terraform Import**        | [![Terraform Import](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-import.yml/badge.svg)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-import.yml)                 | Import existing resources into state    |
| **Terraform Destroy**       | [![Terraform Destroy](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-destroy.yml/badge.svg)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-destroy.yml)              | Clean up resources                      |

### Quick Actions
[![Run Plan & Apply](https://img.shields.io/badge/▶️%20Deploy-Plan%20&%20Apply-brightgreen?style=for-the-badge)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-plan-apply.yml)
[![Run Tests](https://img.shields.io/badge/🧪%20Test-Validate-blue?style=for-the-badge)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions/workflows/terraform-test.yml)
[![View All](https://img.shields.io/badge/📊%20View%20All-Actions-yellow?style=for-the-badge)](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/actions)

</div>

---

## 🚀 Quick Start

### 📋 Prerequisites

Before using this repository, ensure you have:

- **Power Platform admin access** in your tenant
- **Azure subscription** with appropriate permissions
- **Terraform** >= 1.5.0 installed
- **Power Platform CLI** installed
- **Azure CLI** installed and configured

### 1. Setup Infrastructure

The fastest way to get started is using the configuration-driven setup:

```bash
# Copy configuration template
cp config.env.example config.env

# Edit with your values (only GitHub owner/repo required)
vim config.env

# Run complete setup
./scripts/setup/setup.sh
./setup.sh
```

This will automatically:
- ✅ Create Azure AD Service Principal with OIDC
- ✅ Create Terraform backend storage with JIT access
- ✅ Create GitHub repository secrets
- ✅ Configure everything for CI/CD

### 2. Deploy Power Platform Governance

After setup, go to your GitHub repository and run the **Terraform Plan and Apply** workflow:

1. Navigate to **Actions** tab
2. Select **Terraform Plan and Apply** workflow
3. Choose your configuration (e.g., `02-dlp-policy`)
4. Select your tfvars file (e.g., `dlp-finance`)
5. Click **Run workflow**

---

## 📁 Repository Structure

```plaintext
├── .devcontainer/                      # Development container configuration
├── .github/                            # GitHub workflows and actions
├── configurations/                     # Ready-to-use Terraform configurations
│   ├── 02-dlp-policy/                  # DLP policy configuration
│   │   ├── tfvars/                     # Multiple DLP policy tfvars
│   │   │   ├── dlp-finance.tfvars      # Finance-specific DLP policy
│   │   │   ├── dlp-hr.tfvars           # HR-specific DLP policy
│   │   │   └── dlp-general.tfvars      # General business DLP policy
│   │   ├── main.tf                     # Main Terraform configuration
│   │   └── README.md                   # Configuration documentation
│   ├── 03-environment/                 # Environment configuration
│   │   ├── tfvars/                     # Multiple environment tfvars
│   │   │   ├── env-production.tfvars   # Production environment
│   │   │   ├── env-development.tfvars  # Development environment
│   │   │   └── env-sandbox.tfvars      # Sandbox environment
│   │   ├── main.tf                     # Main Terraform configuration
│   │   └── README.md                   # Configuration documentation
│   └── ...                             # Additional configurations
├── docs/                               # Documentation and guides
├── modules/                            # Reusable Terraform modules
├── scripts/                            # Helper scripts for setup and deployments
├── .gitignore                          # Git ignore file
├── CHANGELOG.md                        # Version history and changes
├── LICENSE                             # MIT License
└── README.md                           # This file
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Support

This repository serves as demonstration materials from the PPCC25 session. For questions:
- Review the session materials and documentation
- For general Power Platform questions, use the [Power Platform Community](https://powerplatform.microsoft.com/en-us/community/)
- For Terraform-related questions, refer to the [Terraform documentation](https://developer.hashicorp.com/terraform/docs)