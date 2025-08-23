#!/bin/bash
# ==============================================================================
# Script Name: github-actions-data.sh  
# Purpose: Data fetching utilities for GitHub Actions consumption analysis
# Usage: source this file to use data fetching functions
# Dependencies: GitHub CLI (gh), jq, common.sh
# Author: PPCC25 Demo
# ==============================================================================

# Source common utilities if not already loaded
if [[ "${COLORS_LOADED:-}" != "true" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
fi

# Constants for data fetching
readonly MAX_RUNS_TO_ANALYZE=500  # WHY: Limit to prevent excessive API calls
readonly PAGE_SIZE=100            # WHY: GitHub API maximum page size
readonly CACHE_DIR="${HOME}/.cache/gh-actions-analyzer"

# Fetch workflow runs for specified date range with pagination
# Parameters:
#   $1 - repository (owner/name)
#   $2 - start date (YYYY-MM-DD)
#   $3 - end date (YYYY-MM-DD)
#   $4 - output file path
# Returns: 0 on success, 1 on failure
fetch_workflow_runs() {
    local repo="$1"
    local start_date="$2"
    local end_date="$3"
    local output_file="$4"
    
    print_step "Fetching workflow runs for $repo..."
    
    local page=1
    local total_fetched=0
    local has_more=true
    
    # WHY: Initialize empty JSON array for incremental processing
    echo "[]" > "$output_file"
    
    while [[ "$has_more" == "true" ]] && [[ $total_fetched -lt $MAX_RUNS_TO_ANALYZE ]]; do
        print_info "Processing page $page (${total_fetched} runs so far)..."
        
        # WHY: Direct API call without retry wrapper to avoid output pollution
        local api_response
        if ! api_response=$(gh api "repos/${repo}/actions/runs" \
            --paginate=false \
            -X GET \
            -F per_page="${PAGE_SIZE}" \
            -F page="${page}" \
            -F created=">=${start_date}" 2>/dev/null); then
            print_warning "Failed to fetch page $page, continuing with available data"
            break
        fi
        
        # WHY: Validate API response before processing
        if ! validate_json "$api_response" "GitHub API response"; then
            print_warning "Invalid JSON response on page $page, continuing with available data"
            break
        fi
        
        # WHY: Process runs incrementally to avoid memory issues
        local runs_count
        runs_count=$(echo "$api_response" | jq '.workflow_runs | length')
        
        if [[ "$runs_count" -eq 0 ]]; then
            has_more=false
        else
            # WHY: Filter for completed runs (date filtering already done by API)
            echo "$api_response" | jq -c \
                '.workflow_runs[]? | select(.status == "completed")' | \
                while IFS= read -r run; do
                    echo "$run" >> "${output_file}.tmp"
                done
            
            total_fetched=$((total_fetched + runs_count))
            page=$((page + 1))
        fi
        
        # WHY: Rate limit protection
        sleep 0.5
    done
    
    # WHY: Convert to proper JSON array
    if [[ -f "${output_file}.tmp" ]]; then
        jq -s '.' "${output_file}.tmp" > "$output_file"
        rm -f "${output_file}.tmp"
    fi
    
    local final_count
    final_count=$(jq 'length' "$output_file")
    print_success "Fetched $final_count completed workflow runs"
    return 0
}

# Analyze jobs for workflow runs and calculate billable minutes
# Parameters:
#   $1 - runs file path
#   $2 - results file path
#   $3 - repository owner
#   $4 - repository name
# Returns: 0 on success, 1 on failure
analyze_workflow_jobs() {
    local runs_file="$1"
    local results_file="$2"
    local repo_owner="$3"
    local repo_name="$4"
    
    print_step "Analyzing workflow jobs for billing calculation..."
    
    # WHY: Ensure cache directory exists for job data
    mkdir -p "$CACHE_DIR"
    
    # WHY: Initialize results file with header
    echo "workflow_name|run_id|job_name|billable_minutes|duration_minutes|runner_multiplier|started_at" > "$results_file"
    
    local processed=0
    local total_runs
    total_runs=$(jq 'length' "$runs_file")
    
    jq -c '.[]' "$runs_file" | while IFS= read -r run; do
        local run_id workflow_name
        run_id=$(echo "$run" | jq -r '.id')
        workflow_name=$(echo "$run" | jq -r '.name')
        
        # WHY: Use cache to avoid redundant API calls
        local cache_file="${CACHE_DIR}/${repo_owner//\//_}_${repo_name//\//_}_${run_id}.json"
        local jobs_data
        
        if [[ -f "$cache_file" ]] && [[ -s "$cache_file" ]]; then
            # WHY: Debug - check cached data for retry messages before using
            if grep -q "Attempt.*of.*:" "$cache_file"; then
                print_warning "Cache file contains retry messages, clearing: $cache_file"
                rm -f "$cache_file"
                jobs_data=""
            else
                jobs_data=$(cat "$cache_file")
            fi
        fi
        
        if [[ -z "${jobs_data:-}" ]]; then
            # WHY: Direct API call without retry wrapper to avoid output pollution
            if jobs_data=$(gh api "repos/${repo_owner}/${repo_name}/actions/runs/${run_id}/jobs" -X GET 2>/dev/null); then
                # WHY: Debug - check if response is valid JSON before caching
                if echo "$jobs_data" | jq empty 2>/dev/null; then
                    echo "$jobs_data" > "$cache_file"
                else
                    print_warning "Invalid JSON response for run $run_id, skipping. Response: ${jobs_data:0:100}..."
                    continue
                fi
            else
                print_warning "Failed to fetch jobs for run $run_id, skipping"
                continue
            fi
        fi
        
        # WHY: Process each job for billing calculation
        if echo "$jobs_data" | jq -c '.jobs[]' >/dev/null 2>&1; then
            echo "$jobs_data" | jq -c '.jobs[]' | while IFS= read -r job; do
                local job_name started_at completed_at runner_name
                job_name=$(echo "$job" | jq -r '.name')
                started_at=$(echo "$job" | jq -r '.started_at // empty')
                completed_at=$(echo "$job" | jq -r '.completed_at // empty')
                runner_name=$(echo "$job" | jq -r '.runner_name // "ubuntu-latest"')
                
                if [[ -n "$started_at" ]] && [[ -n "$completed_at" ]]; then
                    # WHY: Calculate duration with proper rounding for billing
                    local duration_seconds duration_minutes multiplier
                    duration_seconds=$(( $(date -d "$completed_at" +%s) - $(date -d "$started_at" +%s) ))
                    duration_minutes=$(( (duration_seconds + 59) / 60 ))  # Round up
                    
                    # WHY: Apply GitHub Actions billing multipliers
                    case "$runner_name" in
                        *windows*|*Windows*) multiplier=2 ;;
                        *macos*|*macOS*) multiplier=10 ;;
                        *) multiplier=1 ;;
                    esac
                    
                    local billable_minutes=$((duration_minutes * multiplier))
                    
                    # WHY: Output in parseable format for analysis
                    echo "${workflow_name}|${run_id}|${job_name}|${billable_minutes}|${duration_minutes}|${multiplier}|${started_at}"
                fi
            done >> "$results_file"
        else
            print_warning "Failed to parse jobs data for run $run_id (workflow: $workflow_name). First 100 chars: ${jobs_data:0:100}..."
        fi
        
        processed=$((processed + 1))
        # WHY: Show progress every 10 runs to avoid excessive output
        if (( processed % 10 == 0 )) || (( processed == total_runs )); then
            printf "\r\033[K"  # Clear line
            print_status "Progress: $processed/$total_runs runs processed"
        fi
    done
    printf "\r\033[K"  # Clear final progress line
    
    return 0
}

# Export functions for use in other scripts
export -f fetch_workflow_runs analyze_workflow_jobs
