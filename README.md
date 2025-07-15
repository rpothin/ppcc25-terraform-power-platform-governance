# Power Platform Governance with Terraform - PPCC25

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4?logo=terraform)](https://www.terraform.io/)
[![Power Platform](https://img.shields.io/badge/Power%20Platform-742774?logo=microsoft)](https://powerplatform.microsoft.com/)

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

## 📋 Prerequisites

Before using this repository, ensure you have:

- **Power Platform admin access** in your tenant
- **Azure subscription** with appropriate permissions
- **Terraform** >= 1.5.0 installed
- **Power Platform CLI** installed
- **Azure CLI** installed and configured

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

## 🏗️ tfvars Management Strategy

This project uses a **configuration-scoped tfvars approach** that aligns with Power Platform's tenant-level nature:

### Structure
- **Root level**: `terraform.tfvars` - Shared tenant-wide configuration
- **Configuration level**: `configurations/<config>/tfvars/<specific>.tfvars` - Required specific configurations

### Usage Examples
```bash
# Deploy Finance-specific DLP policy  
Configuration: 02-dlp-policy
tfvars file: dlp-finance

# Deploy HR-specific DLP policy
Configuration: 02-dlp-policy
tfvars file: dlp-hr

# Deploy production environment
Configuration: 03-environment
tfvars file: env-production

# Deploy development environment
Configuration: 03-environment
tfvars file: env-development
```

### Key Benefits
- **Explicit Configuration**: No default fallback - requires intentional tfvars selection
- **Clear Intent**: Each deployment explicitly states which configuration variant to use
- **Simplified Input**: Only specify the meaningful name (e.g., `dlp-finance`) without file extension
- **Maintainability**: Easy to add new variants without affecting existing configurations
- **Governance**: Enforces deliberate decision-making for each deployment

## 🎉 PPCC25 Attendees

Welcome to the session materials! This repository contains all the code and examples from the presentation. Follow these steps to get started:

1. **Review the prerequisites** above
2. **Explore the configurations** in the `configurations/` folder
3. **Check the documentation** in the `docs/` folder
4. **Run the examples** using the provided scripts

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Support

This repository serves as demonstration materials from the PPCC25 session. For questions:
- Review the session materials and documentation
- For general Power Platform questions, use the [Power Platform Community](https://powerplatform.microsoft.com/en-us/community/)
- For Terraform-related questions, refer to the [Terraform documentation](https://developer.hashicorp.com/terraform/docs)