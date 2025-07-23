#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# YAML VALIDATION TOOLS INSTALLATION LIBRARY
# ═══════════════════════════════════════════════════════════════════════════════
# Reusable functions for installing and configuring YAML validation tools
# across different environments (devcontainer, CI/CD, local development).
#
# 🎯 PURPOSE:
# - Provide consistent tool installation across environments
# - Enable reusable installation patterns for different contexts
# - Support both automated and interactive installation scenarios
# - Maintain version consistency and error handling standards
#
# 🔧 USAGE:
# - source scripts/utils/yaml-tools-installer.sh
# - install_yamllint
# - install_actionlint  
# - install_yq
# - verify_yaml_tools
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# === DYNAMIC VERSION DETECTION ===

get_latest_yamllint_version() {
    # Get latest yamllint version from PyPI API
    local version
    version=$(curl -s "https://pypi.org/pypi/yamllint/json" | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['info']['version'])" 2>/dev/null) || {
        echo "1.35.1"  # Fallback version
        return 0
    }
    echo "$version"
}

get_latest_actionlint_version() {
    # Get latest actionlint version from GitHub API
    local version
    version=$(curl -s "https://api.github.com/repos/rhysd/actionlint/releases/latest" | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))" 2>/dev/null) || {
        echo "1.7.1"  # Fallback version
        return 0
    }
    echo "$version"
}

get_latest_yq_version() {
    # Get latest yq version from GitHub API
    local version
    version=$(curl -s "https://api.github.com/repos/mikefarah/yq/releases/latest" | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))" 2>/dev/null) || {
        echo "4.42.1"  # Fallback version
        return 0
    }
    echo "$version"
}

get_latest_pyyaml_version() {
    # Get latest PyYAML version from PyPI API
    local version
    version=$(curl -s "https://pypi.org/pypi/pyyaml/json" | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['info']['version'])" 2>/dev/null) || {
        echo "6.0.1"  # Fallback version
        return 0
    }
    echo "$version"
}

# === TOOL VERSIONS ===
# Dynamically fetch latest versions with fallback to known stable versions
readonly YAMLLINT_VERSION="$(get_latest_yamllint_version)"
readonly ACTIONLINT_VERSION="$(get_latest_actionlint_version)"  
readonly YQ_VERSION="$(get_latest_yq_version)"
readonly PYYAML_VERSION="$(get_latest_pyyaml_version)"

# === INSTALLATION FUNCTIONS ===

install_yamllint() {
    echo "📦 Installing yamllint for YAML linting..."
    echo "   └── Detected latest version: $YAMLLINT_VERSION"
    if ! command -v yamllint &> /dev/null; then
        pip3 install --user --upgrade "yamllint==$YAMLLINT_VERSION" "pyyaml==$PYYAML_VERSION" || {
            echo "⚠️  Some Python packages may already be installed"
            return 0
        }
        echo "✅ yamllint $YAMLLINT_VERSION installed"
    else
        echo "✅ yamllint already available: $(yamllint --version 2>/dev/null || echo 'installed')"
    fi
}

install_actionlint() {
    echo "📦 Installing actionlint for GitHub Actions validation..."
    echo "   └── Detected latest version: $ACTIONLINT_VERSION"
    if ! command -v actionlint &> /dev/null; then
        # Download and install actionlint
        local temp_dir="/tmp/actionlint-install"
        mkdir -p "$temp_dir"
        
        curl -sSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" | \
            tar -xz -C "$temp_dir" actionlint
        
        # Try system installation first, fallback to user bin
        if sudo mv "$temp_dir/actionlint" /usr/local/bin/actionlint 2>/dev/null; then
            sudo chmod +x /usr/local/bin/actionlint
        else
            # Fallback to user bin
            mkdir -p ~/bin
            mv "$temp_dir/actionlint" ~/bin/actionlint
            chmod +x ~/bin/actionlint
            export PATH="$HOME/bin:$PATH"
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        fi
        
        rm -rf "$temp_dir"
        echo "✅ actionlint $ACTIONLINT_VERSION installed"
    else
        echo "✅ actionlint already available: $(actionlint --version 2>/dev/null || echo 'installed')"
    fi
}

install_yq() {
    echo "📦 Installing yq for YAML processing..."
    echo "   └── Detected latest version: $YQ_VERSION"
    if ! command -v yq &> /dev/null; then
        # Try system installation first, fallback to user bin
        if sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" 2>/dev/null; then
            sudo chmod +x /usr/local/bin/yq
        else
            # Fallback to user bin
            mkdir -p ~/bin
            wget -qO ~/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
            chmod +x ~/bin/yq
            export PATH="$HOME/bin:$PATH"
            echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        fi
        
        echo "✅ yq $YQ_VERSION installed"
    else
        echo "✅ yq already available: $(yq --version 2>/dev/null || echo 'installed')"
    fi
}

create_yamllint_config() {
    local config_file="$1"
    echo "📝 Creating yamllint configuration at $config_file..."
    
    cat > "$config_file" << 'EOF'
# Yamllint configuration optimized for GitHub Actions and Power Platform governance
extends: default

rules:
  line-length:
    max: 100
    allow-non-breakable-words: true
    allow-non-breakable-inline-mappings: true
  comments:
    min-spaces-from-content: 2
  indentation:
    spaces: 2
    indent-sequences: true
    check-multi-line-strings: false
  truthy:
    allowed-values: ['true', 'false', 'on', 'off', 'yes', 'no']
    check-keys: false
  document-start:
    present: true
  empty-lines:
    max: 2
    max-start: 0
    max-end: 1
EOF
    
    echo "✅ Yamllint configuration created"
}

verify_yaml_tools() {
    echo "🔍 Verifying YAML validation tools installation..."
    local tools_ok=true
    
    # Check yamllint
    if command -v yamllint &> /dev/null; then
        echo "✅ yamllint: $(yamllint --version 2>/dev/null || echo 'available')"
    else
        echo "❌ yamllint not found"
        tools_ok=false
    fi
    
    # Check Python YAML
    if python3 -c "import yaml" 2>/dev/null; then
        echo "✅ Python YAML: Available"
    else
        echo "❌ Python YAML module not available"
        tools_ok=false
    fi
    
    # Check actionlint (optional)
    if command -v actionlint &> /dev/null; then
        echo "✅ actionlint: $(actionlint --version 2>/dev/null || echo 'available')"
    else
        echo "⚠️  actionlint: Not available (optional)"
    fi
    
    # Check yq (optional)
    if command -v yq &> /dev/null; then
        echo "✅ yq: $(yq --version 2>/dev/null || echo 'available')"
    else
        echo "⚠️  yq: Not available (optional)"
    fi
    
    if [ "$tools_ok" = true ]; then
        return 0
    else
        return 1
    fi
}

install_all_yaml_tools() {
    echo "🚀 Installing all YAML validation tools..."
    echo
    
    install_yamllint
    install_actionlint  
    install_yq
    
    echo
    verify_yaml_tools
}

# === HELP FUNCTION ===
show_yaml_tools_help() {
    cat << EOF
YAML Tools Installation Library

Available functions:
  install_yamllint        - Install yamllint for YAML linting
  install_actionlint      - Install actionlint for GitHub Actions validation
  install_yq              - Install yq for YAML processing
  create_yamllint_config  - Create project yamllint configuration
  verify_yaml_tools       - Verify all tools are properly installed
  install_all_yaml_tools  - Install all tools in sequence

Usage:
  source scripts/utils/yaml-tools-installer.sh
  install_all_yaml_tools

Tool versions (dynamically detected):
  yamllint: $YAMLLINT_VERSION
  actionlint: $ACTIONLINT_VERSION
  yq: $YQ_VERSION
  pyyaml: $PYYAML_VERSION

Note: Latest versions are automatically detected from official repositories.
      Fallback to known stable versions if detection fails.
EOF
}
