#!/bin/bash
# ==============================================================================
# Script Name: check-actions-minutes-consumption-rate.sh
# Purpose: Monitor GitHub Actions consumption rate vs monthly progress
# Usage: ./check-actions-minutes-consumption-rate.sh [--threshold 1.5]
# Dependencies: GitHub CLI (gh), jq, bc
# Author: PPCC25 Power Platform Governance Demo
# ==============================================================================

set -euo pipefail

# Source common utilities for consistent output
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/common.sh" ]] && source "$SCRIPT_DIR/common.sh"

# Fallback functions if common.sh unavailable
for func in print_success print_error print_warning print_info print_step; do
    if ! type "$func" &>/dev/null; then
        case "$func" in
            print_success) print_success() { echo "✅ $*"; } ;;
            print_error) print_error() { echo "🔴 $*" >&2; } ;;
            print_warning) print_warning() { echo "⚠️ $*" >&2; } ;;
            print_info) print_info() { echo "💡 $*"; } ;;
            print_step) print_step() { echo "🔄 $*"; } ;;
        esac
    fi
done

readonly SCRIPT_VERSION="1.0.0"
readonly INCLUDED_MINUTES=3000

# Global variables
DETAILED_MODE=false

cleanup() {
    [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT SIGINT SIGTERM

# Validate prerequisites and authentication
validate_prerequisites() {
    print_step "Validating prerequisites..."
    
    local missing_tools=()
    for tool in gh jq bc; do
        command -v "$tool" &>/dev/null || missing_tools+=("$tool")
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing tools: ${missing_tools[*]}"
        print_info "Install: sudo apt-get install ${missing_tools[*]}"
        return 1
    fi
    
    if ! gh auth status &>/dev/null; then
        print_error "GitHub CLI not authenticated. Run: gh auth login"
        return 1
    fi
    
    print_success "Prerequisites validated"
}

# Get GitHub Actions billing data
get_billing_data() {
    print_step "Fetching billing data..."
    
    local current_user current_month billing_response monthly_usage
    current_user=$(gh api user --jq '.login' 2>/dev/null) || {
        print_error "Failed to get user info. Run: gh auth status"
        return 1
    }
    
    current_month=$(date +%Y-%m)
    
    if ! billing_response=$(gh api -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/users/$current_user/settings/billing/usage" 2>&1); then
        print_error "API access failed. Try: gh auth refresh -s user"
        return 1
    fi
    
    monthly_usage=$(echo "$billing_response" | jq --arg month "$current_month" \
        '[.usageItems[] | select(.date | startswith($month))]')
    
    TOTAL_PAID_MINUTES=$(echo "$monthly_usage" | jq -r \
        '[.[] | select(.product == "actions" and .unitType == "Minutes") | .quantity] | add // 0')
    
    # Store detailed repository data if requested
    if [[ "$DETAILED_MODE" == "true" ]]; then
        REPO_BREAKDOWN=$(echo "$monthly_usage" | jq -r \
            '[.[] | select(.product == "actions" and .unitType == "Minutes")] | 
             group_by(.repositoryName) | 
             map({repository: .[0].repositoryName, minutes: (map(.quantity) | add)}) | 
             sort_by(-.minutes)')
    fi
    
    [[ "$TOTAL_PAID_MINUTES" =~ ^[0-9]+(\.[0-9]+)?$ ]] || {
        print_error "Invalid billing data received"
        return 1
    }
    
    TOTAL_PAID_MINUTES=${TOTAL_PAID_MINUTES%.*}  # Convert to integer
    print_success "Retrieved: ${TOTAL_PAID_MINUTES}/${INCLUDED_MINUTES} minutes for $current_month"
}

# Calculate consumption metrics and evaluate
calculate_and_evaluate() {
    print_step "Analyzing consumption..."
    
    local current_day days_in_month
    current_day=$((10#$(date +%d)))
    days_in_month=$(date -d "$(date +%Y-%m-01) + 1 month - 1 day" +%d)
    
    CONSUMPTION_PERCENTAGE=$(echo "scale=2; $TOTAL_PAID_MINUTES * 100 / $INCLUDED_MINUTES" | bc)
    MONTHLY_PROGRESS=$(echo "scale=2; $current_day * 100 / $days_in_month" | bc)
    
    if (( $(echo "$MONTHLY_PROGRESS > 0" | bc -l) )); then
        CONSUMPTION_RATE=$(echo "scale=2; $CONSUMPTION_PERCENTAGE / $MONTHLY_PROGRESS" | bc)
    else
        CONSUMPTION_RATE="0.00"
    fi
    
    # Determine threshold based on month position
    if [[ -n "${1:-}" ]]; then
        RATE_THRESHOLD="$1"
        print_info "Using threshold override: ${RATE_THRESHOLD}x"
    elif (( $(echo "$MONTHLY_PROGRESS < 10" | bc -l) )); then
        RATE_THRESHOLD="2.0"
        print_info "Early month: lenient threshold (${RATE_THRESHOLD}x)"
    elif (( $(echo "$MONTHLY_PROGRESS > 80" | bc -l) )); then
        RATE_THRESHOLD="1.1"
        print_info "Late month: strict threshold (${RATE_THRESHOLD}x)"
    else
        RATE_THRESHOLD="1.3"
        print_info "Mid-month: standard threshold (${RATE_THRESHOLD}x)"
    fi
    
    print_success "Rate: ${CONSUMPTION_RATE}x vs ${RATE_THRESHOLD}x threshold"
}

# Display per-repository breakdown when in detailed mode
display_repository_breakdown() {
    if [[ "$DETAILED_MODE" != "true" ]] || [[ -z "${REPO_BREAKDOWN:-}" ]]; then
        return 0
    fi
    
    echo ""
    echo "📊 Repository Breakdown (Actions Minutes)"
    echo "========================================="
    
    local repo_count
    repo_count=$(echo "$REPO_BREAKDOWN" | jq 'length')
    
    if [[ "$repo_count" -eq 0 ]]; then
        print_info "No Actions minutes consumed this month"
        return 0
    fi
    
    echo "$REPO_BREAKDOWN" | jq -r '.[] | 
        "📁 " + (.repository // "<unknown>") + ": " + (.minutes | tostring) + " minutes (" + 
        ((.minutes * 100 / '$TOTAL_PAID_MINUTES') | tonumber | . * 100 | round / 100 | tostring) + "%)"'
    
    echo ""
    print_info "Total repositories with Actions usage: $repo_count"
}

# Display analysis and determine status
display_and_evaluate() {
    local projected_usage
    
    echo ""
    echo "📊 GitHub Actions Consumption Analysis"
    echo "======================================"
    echo "📅 Progress: ${current_day:-$(date +%d)}/${days_in_month:-$(date -d "$(date +%Y-%m-01) + 1 month - 1 day" +%d)} days (${MONTHLY_PROGRESS}%)"
    echo "⚡ Consumed: ${TOTAL_PAID_MINUTES}/${INCLUDED_MINUTES} (${CONSUMPTION_PERCENTAGE}%)"
    echo "📈 Rate: ${CONSUMPTION_RATE}x vs ${RATE_THRESHOLD}x threshold"
    
    if (( $(echo "$MONTHLY_PROGRESS > 0" | bc -l) )); then
        projected_usage=$(echo "scale=0; $CONSUMPTION_PERCENTAGE * 100 / $MONTHLY_PROGRESS" | bc)
        echo "📈 Projected: ${projected_usage}% of monthly budget"
    fi
    
    echo ""
    
    # Show repository breakdown if requested
    display_repository_breakdown
    
    # Check if over budget regardless of rate
    if [[ $TOTAL_PAID_MINUTES -gt $INCLUDED_MINUTES ]]; then
        print_error "CRITICAL - Monthly limit exceeded (${CONSUMPTION_PERCENTAGE}%)"
        return 1
    fi
    
    # Check consumption rate
    if (( $(echo "$CONSUMPTION_RATE <= $RATE_THRESHOLD" | bc -l) )); then
        print_success "GOOD - Consumption within acceptable range"
        [[ -n "${projected_usage:-}" ]] && print_info "Projected usage: ~${projected_usage}%"
        return 0
    else
        print_error "CRITICAL - Consuming too fast! Projected: ${projected_usage:-N/A}%"
        print_info "Actions: Check workflows, cancel unnecessary runs"
        print_info "Analyze: scripts/utils/analyze-actions-minutes-consumption.sh"
        return 1
    fi
}

# Main execution
main() {
    local threshold_override=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --threshold) threshold_override="$2"; shift 2 ;;
            --detailed) DETAILED_MODE=true; shift ;;
            -h|--help)
                echo "Usage: $0 [--threshold RATE] [--detailed]"
                echo "Monitor GitHub Actions consumption rate vs monthly progress"
                echo "Options:"
                echo "  --threshold RATE  Override threshold (e.g., 1.5)"
                echo "  --detailed        Show per-repository consumption breakdown"
                echo "  -h, --help        Show help"
                exit 0 ;;
            *) print_error "Unknown option: $1"; exit 1 ;;
        esac
    done
    
    validate_prerequisites || return 1
    get_billing_data || return 1
    calculate_and_evaluate "$threshold_override" || return 1
    display_and_evaluate || return 1
}

main "$@"
