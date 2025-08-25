#!/bin/bash
# ==============================================================================
# Script Name: quick-github-auth-setup.sh
# Purpose: Setup GitHub CLI authentication with billing permissions
# Usage: ./quick-github-auth-setup.sh
# Dependencies: GitHub CLI (gh)
# Author: PPCC25 Power Platform Governance Demo
# ==============================================================================

set -euo pipefail

echo "🔐 GitHub Authentication Setup"
echo "=============================="
echo "Setting up GitHub CLI with billing permissions..."
echo ""

# Clear existing authentication
unset GITHUB_TOKEN 2>/dev/null || true
gh auth logout 2>/dev/null || echo "No active session found"

echo "� Authenticating with GitHub (browser required)..."
gh auth login --scopes "user"

echo ""
echo "✅ Testing billing API access..."
if gh api user/settings/billing/actions &>/dev/null; then
    echo "✅ SUCCESS! Ready to run consumption monitor:"
    echo "  ./scripts/utils/check-actions-minutes-consumption-rate.sh"
else
    echo "❌ FAILED! Billing API access denied."
    echo "� Ensure you granted the 'user' scope during authentication."
fi
