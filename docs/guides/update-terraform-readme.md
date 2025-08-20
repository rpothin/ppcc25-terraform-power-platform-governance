# How to Update Terraform Configuration README Files Locally with terraform-docs

![How-to Guide](https://img.shields.io/badge/Diataxis-How--to%20Guide-green?style=for-the-badge&logo=tools)

This guide shows you how to quickly regenerate the README documentation for any Terraform configuration in your repository using the `terraform-docs` Docker image. This approach works for any configuration or module that follows the standard `.terraform-docs.yml` pattern.

## 📝 Prerequisites

## 🚀 Step-by-Step Instructions

### 1. Navigate to Your Configuration Directory

```bash
cd /workspaces/ppcc25-terraform-power-platform-governance/configurations/<your-config-folder>
```
Replace `<your-config-folder>` with the name of the configuration you want to update (e.g., `res-managed-environment`).

### 2. Run terraform-docs to Update README

```bash
docker run --rm \
  --volume "$(pwd):/terraform-docs" \
  --workdir "/terraform-docs" \
  quay.io/terraform-docs/terraform-docs:0.20.0 \
  -c .terraform-docs.yml .
```
This command will regenerate the README.md file in your current configuration folder using the settings in `.terraform-docs.yml`.

## 🔄 Batch Update All Configurations (Optional)

To update all configurations in one go:

```bash
cd /workspaces/ppcc25-terraform-power-platform-governance
find configurations/ -name ".terraform-docs.yml" | while read config_file; do
  config_dir=$(dirname "$config_file")
  echo "Updating documentation for: $config_dir"
  docker run --rm \
    --volume "$(pwd):/terraform-docs" \
    --workdir "/terraform-docs/$config_dir" \
    quay.io/terraform-docs/terraform-docs:0.20.0 \
    -c ".terraform-docs.yml" .
done
```
This will regenerate README.md for every configuration that has a `.terraform-docs.yml` file.

## ✅ Verify Your Changes

After running the commands, check your changes:

```bash
git status
git diff configurations/<your-config-folder>/README.md
```

_This guide is part of the PPCC25 Power Platform Governance demonstration repository._
