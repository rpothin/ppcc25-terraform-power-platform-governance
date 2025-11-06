# Tutorial: Getting Started with Power Platform Terraform

![Tutorial](https://img.shields.io/badge/Diataxis-Tutorial-blue?style=for-the-badge&logo=book)

**Estimated Time**: 20 minutes  
**Prerequisites**: None - we'll set everything up together  
**You'll Learn**: How to set up your environment and deploy your first Power Platform governance configuration

---

## 🎯 What You'll Build

By the end of this tutorial, you will have:
- ✅ A complete Power Platform Terraform environment
- ✅ Azure authentication configured with OIDC
- ✅ GitHub Actions workflows ready to deploy
- ✅ Your first successful Terraform deployment

## 🎓 Learning Objectives

This tutorial teaches you:
- How to configure secure authentication without storing credentials
- How to set up Terraform backend storage
- How to deploy infrastructure through GitHub Actions
- How to verify your deployment succeeded

---

## Step 1: Get the Prerequisites

Before we begin, make sure you have access to:

### Required Access
- [ ] **Power Platform tenant** with admin rights  
  ➜ Don't have one? [Join Microsoft 365 Developer Program (free)](https://developer.microsoft.com/microsoft-365/dev-program)
- [ ] **Azure subscription** with permission to create resources  
  ➜ Don't have one? [Start free trial](https://azure.microsoft.com/free)
- [ ] **GitHub account**  
  ➜ Don't have one? [Sign up (free)](https://github.com/signup)

### Tool Check (Automatic)
Don't worry about installing tools manually - the setup script checks for you:
- Azure CLI
- GitHub CLI (optional but helpful)
- Git

💡 **Tip**: Using a dev container? All tools are pre-installed!

---

## Step 2: Fork and Clone the Repository

We'll start by getting your own copy of the repository.

1. **Fork the repository** on GitHub:
   - Go to https://github.com/rpothin/ppcc25-terraform-power-platform-governance
   - Click the "Fork" button in the top right
   - Select your GitHub account as the destination

2. **Clone your fork** to your local machine:
   ```bash
   git clone https://github.com/YOUR-USERNAME/ppcc25-terraform-power-platform-governance.git
   cd ppcc25-terraform-power-platform-governance
   ```

💡 **Success Check**: You should now be in the project directory. Run `ls` and you should see folders like `configurations/`, `docs/`, and `scripts/`.

---

## Step 3: Configure Your Environment

Now we'll create a configuration file with your settings.

1. **Copy the example configuration**:
   ```bash
   cp config.env.example config.env
   ```

2. **Edit the configuration file**:
   ```bash
   # Use your preferred editor (nano, vim, code, etc.)
   nano config.env
   ```

3. **Set these two required values**:
   ```bash
   # Required - Your GitHub information
   GITHUB_OWNER="your-github-username"  # ← Change this
   GITHUB_REPO="ppcc25-terraform-power-platform-governance"  # ← And this
   
   # Optional - Leave empty for automatic configuration
   AZURE_SUBSCRIPTION_ID=""  # Auto-detects from your Azure CLI login
   AZURE_TENANT_ID=""        # Auto-detects from your Azure CLI login
   SP_NAME=""                # Auto-generates unique name
   STORAGE_ACCOUNT_NAME=""   # Auto-generates unique name
   ```

4. **Save the file**:
   - In `nano`: Press `Ctrl+X`, then `Y`, then `Enter`
   - In `vim`: Press `Esc`, type `:wq`, press `Enter`

💡 **Tip**: Only the GitHub owner and repo name are required - everything else uses smart defaults!

---

## Step 4: Run the Automated Setup

This is where the magic happens! One script sets up everything.

1. **Make the setup script executable**:
   ```bash
   chmod +x setup.sh
   ```

2. **Run the setup**:
   ```bash
   ./setup.sh
   ```

3. **What the script does** (you'll see progress messages):
   - ✅ Validates your tools and prerequisites
   - ✅ Logs into Azure (prompts for authentication)
   - ✅ Creates an Azure service principal with OIDC
   - ✅ Sets up Terraform state storage in Azure
   - ✅ Configures GitHub repository secrets
   - ✅ Tests the complete setup

**Expected Duration**: 3-5 minutes

💡 **Success Check**: You should see:
```
✅ Setup completed successfully!
✅ Azure service principal created
✅ Terraform backend configured
✅ GitHub secrets created
```

### 🔧 Troubleshooting Common Issues

**Problem**: "Permission denied: setup.sh"
```bash
# Solution: Make the script executable
chmod +x setup.sh
```

**Problem**: "Azure CLI not found"
```bash
# Solution: Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Or use the dev container (recommended)
```

**Problem**: "GitHub CLI not found"
```bash
# Solution: Install GitHub CLI or skip (setup will prompt for manual steps)
# Automated: gh auth login
# Manual: Setup will show you what secrets to create
```

---

## Step 5: Verify Your Setup

Let's make sure everything is working correctly.

1. **Check your GitHub repository**:
   - Go to your GitHub repository
   - Click "Settings" → "Secrets and variables" → "Actions"
   - You should see these secrets:
     - `AZURE_CLIENT_ID`
     - `AZURE_SUBSCRIPTION_ID`
     - `AZURE_TENANT_ID`
     - `POWER_PLATFORM_CLIENT_ID`
     - `POWER_PLATFORM_TENANT_ID`
     - `TERRAFORM_BACKEND_*` (multiple)

2. **Check your Azure resources**:
   ```bash
   # List your resource groups
   az group list --query "[?starts_with(name, 'rg-terraform')].name" -o table
   
   # You should see a resource group for Terraform state
   ```

💡 **Success Check**: If you see the secrets and resource group, you're ready to deploy!

---

## Step 6: Your First Deployment

Now for the exciting part - deploying infrastructure!

We'll deploy a simple utility to export available connectors.

1. **Go to GitHub Actions**:
   - Open your GitHub repository in a browser
   - Click the "Actions" tab at the top

2. **Run the deployment workflow**:
   - Click "Terraform Plan and Apply" in the left sidebar
   - Click "Run workflow" button (top right)
   - Fill in the form:
     - **Configuration**: `utl-export-connectors`
     - **Terraform vars file**: (leave empty)
     - **Environment**: (leave empty)
     - **Apply changes**: ☐ Unchecked (we'll just plan first)
   - Click "Run workflow"

3. **Watch the progress**:
   - Click on the workflow run that just started
   - Watch as Terraform:
     - ✅ Initializes
     - ✅ Plans the changes
     - ✅ Shows what will be created

4. **Review the plan**:
   - Look at the plan output in the workflow logs
   - You should see it will create resources to export connectors

5. **Apply the changes**:
   - Click "Re-run jobs" → "Run workflow"
   - This time, **check** the "Apply changes" box
   - Click "Run workflow"

6. **Wait for completion**:
   - The workflow will apply your configuration
   - Look for the green checkmark ✅

**Expected Duration**: 2-3 minutes

💡 **Success Check**: 
- Workflow shows green checkmark
- In the logs, you see "Apply complete!"
- Outputs show the list of exported connectors

---

## Step 7: View Your Results

Let's see what we created!

1. **Check the workflow artifacts**:
   - In the completed workflow, scroll down to "Artifacts"
   - Download "terraform-outputs"
   - Unzip and open the JSON file
   - You'll see all available Power Platform connectors!

2. **View in Azure Storage** (optional):
   ```bash
   # List Terraform state files
   az storage blob list \
     --account-name YOUR_STORAGE_ACCOUNT \
     --container-name tfstate \
     --output table
   ```

---

## 🎉 Congratulations!

You've successfully:
- ✅ Set up Power Platform Terraform environment
- ✅ Configured secure OIDC authentication
- ✅ Deployed your first configuration
- ✅ Verified the results

## 🎓 What You Learned

In this tutorial, you learned:
- **Infrastructure as Code**: Deployed infrastructure using code instead of clicking
- **OIDC Authentication**: Secured your deployment without storing credentials
- **GitHub Actions**: Automated deployments through CI/CD
- **Terraform Basics**: Initialized, planned, and applied configurations

---

## 🚀 What's Next?

Now that you have a working environment, continue your learning:

### Next Tutorial
**[Deploy Your First DLP Policy](02-first-dlp-policy.md)** - Learn how to create and manage Data Loss Prevention policies using Terraform (15 minutes)

### Other Learning Paths
- **[Environment Management Tutorial](03-environment-management.md)** - Create and configure Power Platform environments
- **[DLP Policy Management Guide](../guides/dlp-policy-management.md)** - Complete guide to DLP policies
- **[Troubleshooting Guide](../guides/troubleshooting.md)** - Solutions for common issues

### Explore More
- **[Configuration Catalog](../reference/configuration-catalog.md)** - See all available configurations
- **[Architecture Decisions](../explanations/architecture-decisions.md)** - Understand why things work this way

---

## 🆘 Need Help?

**Got stuck?** That's normal when learning! Here's how to get help:

1. **Check the Troubleshooting Guide**: [guides/troubleshooting.md](../guides/troubleshooting.md)
2. **Review setup logs**: Look for error messages in the setup script output
3. **Ask for help**: [Open a discussion](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
4. **Report bugs**: [Create an issue](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/issues)

---

**Tutorial Version**: 1.0.0  
**Last Updated**: 2025-01-06  
**Feedback**: Help us improve this tutorial! [Share your experience](https://github.com/rpothin/ppcc25-terraform-power-platform-governance/discussions)
