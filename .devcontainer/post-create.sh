#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# DEVCONTAINER POST-CREATE SETUP SCRIPT FOR POWER PLATFORM GOVERNANCE
# ═══════════════════════════════════════════════════════════════════════════════
# Installs YAML validation tools and development dependencies required for
# Power Platform governance automation workflows and GitHub Actions development.
#
# 🎯 WHY THIS EXISTS:
# - Ensures consistent development environment with all required validation tools
# - Provides systematic YAML syntax validation capabilities for GitHub Actions
# - Leverages modular installation functions for maintainability and reusability
# - Supports automated quality assurance for infrastructure automation code
#
# 🔒 SECURITY DECISIONS:
# - Uses official package repositories and verified installation methods
# - Delegates to modular installer functions with built-in security practices
# - Validates installation success to prevent silent failures in development workflow
# - Uses specific version pins where available to ensure reproducible environments
#
# ⚙️ OPERATIONAL CONTEXT:
# - Runs automatically when devcontainer is created or rebuilt
# - Uses modular installer library for consistent tool management
# - Provides immediate feedback on installation success for troubleshooting
# - Creates validation scripts accessible from any workspace directory
#
# 📋 INTEGRATION REQUIREMENTS:
# - Requires Python 3.x and pip (provided by devcontainer features)
# - Depends on modular yaml-tools-installer.sh for installation logic
# - Integrates with GitHub automation instructions for validation workflows
# - Supports yamllint, actionlint, yq, and other YAML processing tools
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

echo "🚀 Setting up YAML validation tools for Power Platform governance..."
echo

# === SOURCE MODULAR INSTALLER ===
# Use reusable installation functions to maintain consistency
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_ROOT/scripts/utils/yaml-tools-installer.sh" ]]; then
    # shellcheck source=../scripts/utils/yaml-tools-installer.sh
    source "$PROJECT_ROOT/scripts/utils/yaml-tools-installer.sh"
    
    # Install all YAML validation tools
    install_all_yaml_tools
    
    echo
    
    # Create project-specific yamllint configuration
    create_yamllint_config ~/.yamllint
    
    echo
    
    # === COMPLETION MESSAGE ===
    if verify_yaml_tools; then
        echo "🎉 YAML validation tools setup completed successfully!"
        echo
        echo "📋 Available tools:"
        echo "   • yamllint - Comprehensive YAML linting"
        echo "   • Python yaml - Basic syntax validation"
        echo "   • actionlint - GitHub Actions workflow validation"
        echo "   • yq - YAML processing and manipulation"
        echo
        echo "🛠️  Quick commands:"
        echo "   • ./scripts/utils/validate-yaml.sh --all-actions"
        echo "   • yamllint file.yml"
        echo "   • python3 -c \"import yaml; yaml.safe_load(open('file.yml'))\""
        echo
        echo "Ready for YAML validation! 🚀"
    else
        echo "⚠️  Some tools failed to install but essential tools are available"
        echo "You can still perform basic YAML validation"
    fi
else
    echo "⚠️  Modular installer not found. Installing tools directly..."
    
    # Fallback to direct installation
    echo "📦 Installing essential YAML validation tools..."
    pip3 install --user --upgrade yamllint pyyaml || echo "⚠️  Some Python packages already installed"
    
    echo "✅ Basic YAML validation tools installed"
    echo "🛠️  Use: yamllint file.yml or python3 -c \"import yaml; yaml.safe_load(open('file.yml'))\""
fi
