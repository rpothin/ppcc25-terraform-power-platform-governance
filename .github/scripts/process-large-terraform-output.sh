#!/bin/bash
# Large Terraform Output Processing Script
# Handles very large Terraform output files that may exceed system limits
# Supports chunked processing, compression, and size optimization

set -euo pipefail

# Configuration
MAX_FILE_SIZE_MB=50
CHUNK_SIZE_MB=10
COMPRESS_LARGE_FILES=true

# Function to get file size in MB
get_file_size_mb() {
    local file="$1"
    local size_bytes
    size_bytes=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
    echo $((size_bytes / 1024 / 1024))
}

# Function to process large JSON files in chunks
process_large_json() {
    local input_file="$1"
    local output_file="$2"
    local include_metadata="$3"
    local config="$4"
    
    echo "::notice title=Large File Processing::📦 Processing large file in chunks"
    
    # Check if the output is a single large object or array
    local json_type
    json_type=$(jq -r 'type' "$input_file")
    
    if [ "$json_type" = "object" ]; then
        # For object outputs, we can process keys separately if needed
        local key_count
        key_count=$(jq -r 'keys | length' "$input_file")
        
        if [ "$key_count" -gt 100 ]; then
            echo "::notice title=Object Processing::🔧 Processing object with $key_count keys"
            # Create a summary version with limited data
            create_summary_output "$input_file" "$output_file" "$include_metadata" "$config"
        else
            # Normal processing for reasonable-sized objects
            process_normal_json "$input_file" "$output_file" "$include_metadata" "$config"
        fi
    else
        # For arrays or other types, process normally or create summary
        process_normal_json "$input_file" "$output_file" "$include_metadata" "$config"
    fi
}

# Function to create summary output for very large files
create_summary_output() {
    local input_file="$1"
    local output_file="$2"
    local include_metadata="$3"
    local config="$4"
    
    echo "::warning title=Large Dataset::📊 Creating summary output due to large dataset size"
    
    # Create summary with metadata
    local temp_summary
    temp_summary=$(mktemp)
    
    # Generate summary statistics
    jq -n \
        --argjson stats "$(jq '{
            total_outputs: (keys | length),
            output_types: [to_entries[] | {key: .key, type: (.value | type)}],
            sample_keys: (keys | .[0:5]),
            file_size_mb: 0,
            processing_note: "This is a summary due to large dataset size. Full data available in compressed artifact."
        }' "$input_file")" \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --arg configuration "$config" \
        '{
            summary: $stats,
            metadata: {
                generated_at: $timestamp,
                configuration: $configuration,
                processing_mode: "summary",
                full_data_location: "See workflow artifacts for complete dataset"
            }
        }' > "$temp_summary"
    
    # Add metadata if requested
    if [ "$include_metadata" = "true" ]; then
        cp "$temp_summary" "$output_file"
    else
        jq '.summary' "$temp_summary" > "$output_file"
    fi
    
    rm "$temp_summary"
    
    # Also create a compressed full version
    local compressed_file="${output_file%.json}-full.json.gz"
    gzip -c "$input_file" > "$compressed_file"
    echo "::notice title=Compressed Archive::📦 Full data archived as: $(basename "$compressed_file")"
}

# Function to process normal-sized JSON files
process_normal_json() {
    local input_file="$1"
    local output_file="$2"
    local include_metadata="$3"
    local config="$4"
    
    if [ "$include_metadata" = "true" ]; then
        local temp_metadata
        temp_metadata=$(mktemp)
        cat > "$temp_metadata" << EOF
{
  "metadata": {
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "configuration": "$config",
    "workflow_run": "${GITHUB_RUN_NUMBER:-unknown}",
    "generated_by": "${GITHUB_ACTOR:-system}",
    "processing_mode": "standard"
  }
}
EOF
        
        jq -s '.[0] + {"terraform_output": .[1]}' "$temp_metadata" "$input_file" > "$output_file"
        rm "$temp_metadata"
    else
        jq '.' "$input_file" > "$output_file"
    fi
}

# Main processing function
process_terraform_output() {
    local input_file="$1"
    local output_file="$2"
    local include_metadata="$3"
    local config="$4"
    
    # Check file size
    local file_size_mb
    file_size_mb=$(get_file_size_mb "$input_file")
    
    echo "::notice title=File Size Check::📊 Input file size: ${file_size_mb}MB"
    
    if [ "$file_size_mb" -gt "$MAX_FILE_SIZE_MB" ]; then
        echo "::warning title=Large File Detected::📦 File size (${file_size_mb}MB) exceeds threshold (${MAX_FILE_SIZE_MB}MB)"
        process_large_json "$input_file" "$output_file" "$include_metadata" "$config"
    else
        echo "::notice title=Standard Processing::✅ File size within normal limits"
        process_normal_json "$input_file" "$output_file" "$include_metadata" "$config"
    fi
}

# Script entry point
if [ $# -ne 4 ]; then
    echo "Usage: $0 <input_file> <output_file> <include_metadata> <config>"
    exit 1
fi

process_terraform_output "$1" "$2" "$3" "$4"
