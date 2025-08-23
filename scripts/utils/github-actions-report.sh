#!/bin/bash
# ==============================================================================
# Script Name: github-actions-report.sh
# Purpose: Generate consumption analysis reports from GitHub Actions data
# Usage: source this file to use report generation functions
# Dependencies: jq, common.sh
# Author: PPCC25 Demo
# ==============================================================================

# Source common utilities if not already loaded
if [[ "${COLORS_LOADED:-}" != "true" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/common.sh"
fi

# Generate comprehensive consumption report from results file
# Parameters:
#   $1 - results file path (CSV format)
#   $2 - repository name for display
# Returns: 0 on success
generate_consumption_report() {
    local results_file="$1"
    local repo_name="$2"
    
    print_step "Generating consumption analysis report..."
    
    # WHY: Validate input file exists and has data
    if [[ ! -f "$results_file" ]] || [[ ! -s "$results_file" ]]; then
        print_error "Results file not found or empty: $results_file"
        return 1
    fi
    
    # WHY: Debug - show sample of results data if in debug mode
    if [[ "${DEBUG:-}" == "true" ]]; then
        print_info "Debug: First 5 lines of results file:"
        head -5 "$results_file"
        print_info "Debug: Total lines in results file: $(wc -l < "$results_file")"
    fi
    
    # WHY: Skip header line and calculate totals
    local total_billable_minutes total_workflows total_jobs
    total_billable_minutes=$(tail -n +2 "$results_file" | cut -d'|' -f4 | awk '{sum+=$1} END {print sum+0}')
    total_workflows=$(tail -n +2 "$results_file" | cut -d'|' -f1 | sort -u | wc -l)
    total_jobs=$(tail -n +2 "$results_file" | wc -l)
    
    echo ""
    echo "🎯 GitHub Actions Consumption Analysis Report"
    echo "=============================================="
    echo "📍 Repository: $repo_name"
    echo "⚡ Total Billable Minutes: $total_billable_minutes"
    echo "📊 Workflows Analyzed: $total_workflows"
    echo "🔧 Jobs Analyzed: $total_jobs"
    echo ""
    
    # WHY: Show top consuming workflows for optimization targeting
    _show_top_workflows "$results_file"
    _show_top_jobs "$results_file"
    _show_workflow_duration_stats "$results_file"
    _show_runner_distribution "$results_file"
    _show_optimization_recommendations "$results_file"
    
    return 0
}

# Display top consuming workflows
# Parameters:
#   $1 - results file path
_show_top_workflows() {
    local results_file="$1"
    
    echo "🔥 Top 10 Workflows by Total Consumption:"
    echo "-----------------------------------------"
    tail -n +2 "$results_file" | cut -d'|' -f1,4 | \
        awk -F'|' '{workflow[$1]+=$2} END {for (w in workflow) print workflow[w] "|" w}' | \
        sort -nr | head -10 | \
        awk -F'|' 'BEGIN {printf "%-8s %s\n", "Minutes", "Workflow"} {printf "%-8d %s\n", $1, $2}'
    echo ""
}

# Display top consuming individual jobs across all workflows
# Parameters:
#   $1 - results file path
_show_top_jobs() {
    local results_file="$1"
    
    echo "⚡ Top 10 Jobs by Total Consumption:"
    echo "-----------------------------------"
    
    # WHY: More robust job aggregation with better error handling
    if ! tail -n +2 "$results_file" | cut -d'|' -f1,3,4 | \
        awk -F'|' '{
            if ($3 != "" && $3 > 0) {
                job_key=$1 " → " $2
                job_consumption[job_key]+=$3
            }
        } END {
            if (length(job_consumption) == 0) {
                print "No job consumption data found"
                exit 1
            }
            for (j in job_consumption) {
                print job_consumption[j] "|" j
            }
        }' | \
        sort -nr | head -10 | \
        awk -F'|' 'BEGIN {printf "%-8s %s\n", "Minutes", "Workflow → Job"} {printf "%-8d %s\n", $1, $2}'; then
        print_warning "Failed to generate job consumption statistics"
    fi
    echo ""
}

# Display per-workflow duration statistics  
# Parameters:
#   $1 - results file path
_show_workflow_duration_stats() {
    local results_file="$1"
    
    echo "⏱️  Workflow Duration Statistics:"
    echo "--------------------------------"
    
    # WHY: Process duration data more carefully and debug potential issues
    if ! tail -n +2 "$results_file" | cut -d'|' -f1,5 | \
        awk -F'|' '{
            if ($2 != "" && $2 > 0) {
                count[$1]++
                sum[$1]+=$2
                if (max[$1] < $2) max[$1] = $2
            }
        } END {
            if (length(sum) == 0) {
                print "No duration data found"
                exit 1
            }
            printf "%-8s %-8s %s\n", "Avg Min", "Max Min", "Workflow"
            printf "%-8s %-8s %s\n", "-------", "-------", "--------"
            for (w in sum) {
                if (count[w] > 0) {
                    avg = sum[w]/count[w]
                    printf "%-8.1f %-8d %s\n", avg, max[w], w
                }
            }
        }' | sort -k1 -nr; then
        print_warning "Failed to generate duration statistics"
    fi
    echo ""
}

# Display runner type distribution
# Parameters:
#   $1 - results file path
_show_runner_distribution() {
    local results_file="$1"
    
    echo "💰 Runner Type Distribution:"
    echo "----------------------------"
    tail -n +2 "$results_file" | cut -d'|' -f4,6 | \
        awk -F'|' '{
            if ($2 == 1) linux+=$1
            else if ($2 == 2) windows+=$1
            else if ($2 == 10) macos+=$1
        } END {
            printf "Linux:   %d minutes (1x multiplier)\n", linux+0
            printf "Windows: %d minutes (2x multiplier)\n", windows+0  
            printf "macOS:   %d minutes (10x multiplier)\n", macos+0
        }'
    echo ""
}

# Display optimization recommendations
# Parameters:
#   $1 - results file path
_show_optimization_recommendations() {
    local results_file="$1"
    
    echo "🎯 Optimization Recommendations:"
    echo "--------------------------------"
    
    # WHY: Identify workflows with high per-job cost
    local high_cost_threshold=15
    echo "• High-cost workflows (>${high_cost_threshold} min/job average):"
    local high_cost_found=false
    
    tail -n +2 "$results_file" | cut -d'|' -f1,4 | \
        awk -F'|' '{workflow[$1]+=$2; count[$1]++} END {
            found = 0
            for (w in workflow) {
                avg = workflow[w]/count[w]
                if (avg > '$high_cost_threshold') {
                    printf "  - %s: %.1f min/job\n", w, avg
                    found = 1
                }
            }
            if (found == 0) print "  ✓ No high-cost workflows found"
        }'
    
    echo ""
    echo "• General recommendations:"
    echo "  - Use path filtering to avoid unnecessary runs"
    echo "  - Implement provider caching for Terraform workflows"
    echo "  - Consider using ubuntu-latest instead of windows/macos when possible"
    echo "  - Review job parallelization opportunities"
}

# Export functions for use in other scripts
export -f generate_consumption_report
