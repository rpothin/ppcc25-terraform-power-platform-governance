#!/bin/bash
# ==============================================================================
# Timing Utilities Library
# ==============================================================================
# Provides timing and performance measurement functions for scripts
# Helps demonstrate ROI of automation by tracking execution times
# ==============================================================================

# Source color utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UTILS_DIR/colors.sh"

# Global variables for timing
declare -A TIMING_START_TIMES
declare -A TIMING_END_TIMES
declare -A TIMING_DURATIONS
declare -A TIMING_DESCRIPTIONS
TIMING_SCRIPT_START=""
TIMING_SCRIPT_END=""
TIMING_SCRIPT_NAME=""

# Function to initialize timing for a script
init_script_timing() {
    local script_name="$1"
    TIMING_SCRIPT_NAME="$script_name"
    TIMING_SCRIPT_START=$(date +%s)
    
    print_status "🕐 Starting timing measurement for: $script_name"
    print_status "Start time: $(date -d @$TIMING_SCRIPT_START '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# Function to start timing a checkpoint
start_timing() {
    local checkpoint_name="$1"
    local description="${2:-$checkpoint_name}"
    
    TIMING_START_TIMES["$checkpoint_name"]=$(date +%s)
    TIMING_DESCRIPTIONS["$checkpoint_name"]="$description"
    
    print_step "🚀 Starting: $description"
    print_status "Checkpoint start time: $(date -d @${TIMING_START_TIMES[$checkpoint_name]} '+%H:%M:%S')"
    echo ""
}

# Function to end timing a checkpoint
end_timing() {
    local checkpoint_name="$1"
    local end_time=$(date +%s)
    
    if [[ -z "${TIMING_START_TIMES[$checkpoint_name]:-}" ]]; then
        print_warning "⚠️  No start time found for checkpoint: $checkpoint_name"
        return 1
    fi
    
    TIMING_END_TIMES["$checkpoint_name"]=$end_time
    local start_time=${TIMING_START_TIMES[$checkpoint_name]}
    local duration=$((end_time - start_time))
    TIMING_DURATIONS["$checkpoint_name"]=$duration
    
    print_success "✅ Completed: ${TIMING_DESCRIPTIONS[$checkpoint_name]}"
    print_success "Duration: $(format_duration $duration)"
    print_status "Checkpoint end time: $(date -d @$end_time '+%H:%M:%S')"
    echo ""
}

# Function to finalize script timing
finalize_script_timing() {
    TIMING_SCRIPT_END=$(date +%s)
    local total_duration=$((TIMING_SCRIPT_END - TIMING_SCRIPT_START))
    
    print_banner "⏱️  TIMING SUMMARY - $TIMING_SCRIPT_NAME"
    echo ""
    
    # Script timing
    print_header "Overall Execution"
    print_status "Script: $TIMING_SCRIPT_NAME"
    print_status "Start time: $(date -d @$TIMING_SCRIPT_START '+%Y-%m-%d %H:%M:%S')"
    print_status "End time: $(date -d @$TIMING_SCRIPT_END '+%Y-%m-%d %H:%M:%S')"
    print_success "Total duration: $(format_duration $total_duration)"
    echo ""
    
    # Checkpoint breakdown
    if [[ ${#TIMING_DURATIONS[@]} -gt 0 ]]; then
        print_header "Checkpoint Breakdown"
        echo ""
        
        # Calculate total checkpoint time and find longest step
        local total_checkpoint_time=0
        local longest_duration=0
        local longest_step=""
        
        # First pass: calculate totals and find longest
        for checkpoint in "${!TIMING_DURATIONS[@]}"; do
            local duration=${TIMING_DURATIONS[$checkpoint]}
            total_checkpoint_time=$((total_checkpoint_time + duration))
            
            if [[ $duration -gt $longest_duration ]]; then
                longest_duration=$duration
                longest_step="$checkpoint"
            fi
        done
        
        # Display checkpoint details in a formatted table
        printf "%-25s %-35s %-12s %s\n" "CHECKPOINT" "DESCRIPTION" "DURATION" "% OF TOTAL"
        printf "%-25s %-35s %-12s %s\n" "----------" "-----------" "--------" "----------"
        
        for checkpoint in "${!TIMING_DURATIONS[@]}"; do
            local duration=${TIMING_DURATIONS[$checkpoint]}
            local description="${TIMING_DESCRIPTIONS[$checkpoint]}"
            
            # Avoid division by zero
            local percentage=0
            if [[ $total_duration -gt 0 ]]; then
                percentage=$(( (duration * 100) / total_duration ))
            fi
            
            local duration_str=$(format_duration $duration)
            
            # Highlight the longest step
            if [[ "$checkpoint" == "$longest_step" ]]; then
                printf "${BOLD}%-25s %-35s %-12s %s%%${NC}\n" "$checkpoint" "$description" "$duration_str" "$percentage"
            else
                printf "%-25s %-35s %-12s %s%%\n" "$checkpoint" "$description" "$duration_str" "$percentage"
            fi
        done
        
        echo ""
        print_status "Total checkpoint time: $(format_duration $total_checkpoint_time)"
        
        # Calculate overhead (time not in measured checkpoints)
        local overhead=$((total_duration - total_checkpoint_time))
        if [[ $overhead -gt 0 && $total_duration -gt 0 ]]; then
            local overhead_percentage=$(( (overhead * 100) / total_duration ))
            print_status "Overhead time: $(format_duration $overhead) (${overhead_percentage}%)"
        fi
        
        echo ""
        if [[ -n "$longest_step" && -n "${TIMING_DESCRIPTIONS[$longest_step]:-}" ]]; then
            print_success "⭐ Longest step: ${TIMING_DESCRIPTIONS[$longest_step]} ($(format_duration $longest_duration))"
        fi
    fi
    
    # ROI Information
    print_header "Return on Investment (ROI) Metrics"
    echo ""
    
    # Estimate manual time
    local estimated_manual_time
    if [[ "$TIMING_SCRIPT_NAME" == *"Setup"* ]]; then
        estimated_manual_time=$((total_duration * 8))  # Conservative estimate: 8x longer manually
    elif [[ "$TIMING_SCRIPT_NAME" == *"Cleanup"* ]]; then
        estimated_manual_time=$((total_duration * 6))  # Cleanup might be slightly faster manually
    else
        estimated_manual_time=$((total_duration * 7))  # Default multiplier
    fi
    
    local time_saved=$((estimated_manual_time - total_duration))
    local efficiency_gain=0
    if [[ $estimated_manual_time -gt 0 ]]; then
        efficiency_gain=$(( ((estimated_manual_time - total_duration) * 100) / estimated_manual_time ))
    fi
    
    print_status "Estimated manual execution time: $(format_duration $estimated_manual_time)"
    print_status "Automated execution time: $(format_duration $total_duration)"
    if [[ $time_saved -gt 0 ]]; then
        print_success "Time saved through automation: $(format_duration $time_saved)"
        print_success "Efficiency gain: ${efficiency_gain}%"
    else
        print_status "Time saved through automation: $(format_duration $time_saved)"
        print_status "Efficiency gain: ${efficiency_gain}%"
    fi
    
    # Additional metrics
    echo ""
    print_status "Additional Benefits:"
    print_status "  • Reduced human error risk through consistent automation"
    print_status "  • Improved repeatability and standardization"
    print_status "  • Enhanced auditability with detailed logging"
    print_status "  • Faster onboarding for new team members"
    print_status "  • Consistent configuration across environments"
    
    echo ""
    print_banner "🎯 Automation provides ${efficiency_gain}% efficiency improvement!"
    
    # Display timing insights
    display_timing_insights
    echo ""
}

# Function to format duration in human-readable format
format_duration() {
    local duration=$1
    
    if [[ $duration -lt 60 ]]; then
        echo "${duration}s"
    elif [[ $duration -lt 3600 ]]; then
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))
        echo "${minutes}m ${seconds}s"
    else
        local hours=$((duration / 3600))
        local minutes=$(((duration % 3600) / 60))
        local seconds=$((duration % 60))
        echo "${hours}h ${minutes}m ${seconds}s"
    fi
}

# Function to get current checkpoint times (for intermediate reporting)
get_timing_summary() {
    local current_time=$(date +%s)
    local current_duration=$((current_time - TIMING_SCRIPT_START))
    
    echo ""
    print_status "⏱️  Current Execution Time: $(format_duration $current_duration)"
    
    if [[ ${#TIMING_DURATIONS[@]} -gt 0 ]]; then
        print_status "Completed checkpoints:"
        for checkpoint in "${!TIMING_DURATIONS[@]}"; do
            local duration=${TIMING_DURATIONS[$checkpoint]}
            print_status "  ✓ ${TIMING_DESCRIPTIONS[$checkpoint]}: $(format_duration $duration)"
        done
    fi
    echo ""
}

# Function to show estimated remaining time (if we have historical data)
estimate_remaining_time() {
    local total_steps="$1"
    local completed_steps="$2"
    local step_description="${3:-steps}"
    
    if [[ $completed_steps -eq 0 || $total_steps -eq 0 ]]; then
        return 0
    fi
    
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - TIMING_SCRIPT_START))
    local avg_time_per_step=$((elapsed_time / completed_steps))
    local remaining_steps=$((total_steps - completed_steps))
    local estimated_remaining=$((avg_time_per_step * remaining_steps))
    
    print_status "📊 Progress: $completed_steps/$total_steps $step_description completed"
    print_status "📈 Estimated remaining time: $(format_duration $estimated_remaining)"
    print_status "🎯 Estimated completion: $(date -d "@$((current_time + estimated_remaining))" '+%H:%M:%S')"
    echo ""
}

# Function to display timing insights
display_timing_insights() {
    echo ""
    print_header "💡 Timing Insights"
    echo ""
    print_status "Key Benefits of This Automation:"
    print_status "  • Performance analysis and optimization opportunities"
    print_status "  • ROI calculations for automation initiatives"
    print_status "  • Resource planning for similar projects"
    print_status "  • Demonstrated automation benefits to stakeholders"
    echo ""
}

# Function to compare timing with previous runs (if historical data exists)
compare_with_baseline() {
    local baseline_file="$1"
    
    if [[ ! -f "$baseline_file" ]]; then
        print_status "No baseline timing data found. This run will serve as baseline."
        return 0
    fi
    
    print_header "Performance Comparison"
    print_status "Comparing with baseline: $baseline_file"
    
    # This is a placeholder for more sophisticated comparison
    # Could be enhanced to parse previous timing reports and show trends
    print_status "Note: Detailed comparison requires enhancement to parse historical data"
    echo ""
}

# Export functions for use in other scripts
export -f init_script_timing start_timing end_timing finalize_script_timing
export -f format_duration get_timing_summary estimate_remaining_time
export -f display_timing_insights compare_with_baseline
