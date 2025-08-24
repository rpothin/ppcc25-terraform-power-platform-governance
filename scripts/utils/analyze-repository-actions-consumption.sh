#!/bin/bash
# ==============================================================================
# Script Name: analyze-repository-actions-consumption.sh
# Purpose: Deep-dive analysis of GitHub Actions consumption for single repository
# Usage: ./analyze-repository-actions-consumption.sh [owner/repo] [--month YYYY-MM]
# Dependencies: GitHub CLI (gh), jq, bc, date
# Author: PPCC25 Demo
# ==============================================================================

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/github-actions-report.sh"
source "$SCRIPT_DIR/github-actions-data.sh"

# WHY: Use print_status for informational messages (colors.sh provides this)
print_info() { print_status "$*"; }

# Global variables
TEMP_DIR=""
REPO_OWNER=""
REPO_NAME=""

# Cleanup function - removes temporary files and caches
cleanup() {
    local exit_code=$?
    [[ -n "${TEMP_DIR:-}" ]] && rm -rf "$TEMP_DIR"
    exit $exit_code
}
# WHY: Use common.sh setup for proper error handling
setup_error_handling cleanup

# Validate required CLI tools are available
# Returns: 0 on success, 1 on failure
validate_dependencies() {
    local missing_tools=()
    
    for tool in gh jq bc date; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Install GitHub CLI: https://cli.github.com/"
        print_info "Install jq: https://stedolan.github.io/jq/"
        return 1
    fi
    
    # WHY: Validate GitHub CLI authentication
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI not authenticated"
        print_info "Run: gh auth login"
        return 1
    fi
    
    return 0
}

# Main function
# Parameters:
#   $@ - command line arguments (supports --month YYYY-MM)
# Returns: 0 on success, 1 on failure
main() {
    local repo=""
    local month=$(date +%Y-%m)  # Default to current month
    
    # WHY: Parse command line arguments properly
    while [[ $# -gt 0 ]]; do
        case $1 in
            --month)
                month="$2"
                shift 2
                ;;
            --help|-h)
                print_info "Usage: $0 [owner/repo] [--month YYYY-MM]"
                print_info "  owner/repo: GitHub repository (optional, auto-detected if not provided)"
                print_info "  --month: Analysis month in YYYY-MM format (optional, defaults to current month)"
                return 0
                ;;
            *)
                if [[ -z "$repo" ]]; then
                    repo="$1"
                else
                    print_error "Unknown argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    print_info "🔍 GitHub Actions Repository Consumption Analyzer"
    print_info "=================================================="
    
    # WHY: Validate dependencies before processing
    if ! validate_dependencies; then
        return 1
    fi
    
    # WHY: Auto-detect repository if not provided
    if [[ -z "$repo" ]]; then
        repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)
        if [[ -z "$repo" ]]; then
            print_error "Repository not specified and could not be detected"
            print_info "Usage: $0 [owner/repo] [--month YYYY-MM]"
            return 1
        fi
    fi
    
    # WHY: Parse repository owner and name for API calls
    REPO_OWNER=$(echo "$repo" | cut -d'/' -f1)
    REPO_NAME=$(echo "$repo" | cut -d'/' -f2)
    
    # WHY: Calculate date range for specified month
    local start_date="${month}-01"
    local end_date
    end_date=$(date -d "${start_date} + 1 month - 1 day" +%Y-%m-%d)
    
    print_info "📅 Analysis Period: $start_date to $end_date"
    
    # WHY: Create secure temporary directory for data processing  
    TEMP_DIR=$(mktemp -d)
    chmod 700 "$TEMP_DIR"  # WHY: Ensure only owner can access temp files
    local runs_file="${TEMP_DIR}/runs.json"
    local results_file="${TEMP_DIR}/results.txt"
    
    # WHY: Execute analysis pipeline
    if ! fetch_workflow_runs "$repo" "$start_date" "$end_date" "$runs_file"; then
        print_error "Failed to fetch workflow runs"
        return 1
    fi
    
    if [[ ! -s "$runs_file" ]] || [[ $(jq 'length' "$runs_file") -eq 0 ]]; then
        print_warning "No completed workflow runs found in specified period"
        return 0
    fi
    
    if ! analyze_workflow_jobs "$runs_file" "$results_file" "$REPO_OWNER" "$REPO_NAME"; then
        print_error "Failed to analyze workflow jobs"
        return 1
    fi
    
    # WHY: Generate report using external module to keep this script focused
    generate_consumption_report "$results_file" "$repo"
    
    # WHY: Debug mode - show sample data format for troubleshooting
    if [[ "${DEBUG:-}" == "true" || "${1:-}" == "--debug" ]]; then
        print_status "🔍 Debug: Sample data format from results file:"
        echo "Header:" 
        head -1 "$results_file"
        echo "First 5 data rows:"
        tail -n +2 "$results_file" | head -5
        echo ""
        echo "Debug files preserved in: $temp_dir"
        return 0
    fi
    
    # WHY: Optionally preserve debug files if DEBUG environment variable is set
    if [[ "${DEBUG:-}" == "true" ]]; then
        print_info "Debug mode: preserving temp files in $TEMP_DIR"
        print_info "Results file: $results_file"
        print_info "Runs file: $runs_file"
    fi
    
    print_success "Analysis completed successfully"
    return 0
}

# WHY: Execute main function with all arguments
main "$@"
