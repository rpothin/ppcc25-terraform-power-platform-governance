#!/bin/bash
# Stream-based Terraform Output Processor
# Uses streaming JSON processing to handle arbitrarily large files
# Memory-efficient approach for very large datasets

set -euo pipefail

# Configuration
STREAM_CHUNK_SIZE=1000  # Process this many items at a time
MAX_MEMORY_MB=100       # Maximum memory usage threshold

# Function to detect if we need streaming processing
needs_streaming() {
    local file="$1"
    local file_size_mb
    file_size_mb=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
    file_size_mb=$((file_size_mb / 1024 / 1024))
    
    [ "$file_size_mb" -gt "$MAX_MEMORY_MB" ]
}

# Stream process large objects by splitting into smaller chunks
stream_process_object() {
    local input_file="$1"
    local output_dir="$2"
    local base_name="$3"
    
    echo "::notice title=Stream Processing::🌊 Processing large object in streaming mode"
    
    # Get all top-level keys
    local keys_file
    keys_file=$(mktemp)
    jq -r 'keys[]' "$input_file" > "$keys_file"
    
    local chunk_num=1
    local current_chunk="{}"
    local items_in_chunk=0
    
    # Create output directory for chunks
    mkdir -p "$output_dir"
    
    while IFS= read -r key; do
        # Extract the value for this key and add to current chunk
        local temp_item
        temp_item=$(mktemp)
        jq -r --arg key "$key" '.[$key]' "$input_file" > "$temp_item"
        
        # Add to current chunk
        local temp_chunk
        temp_chunk=$(mktemp)
        echo "$current_chunk" | jq --arg key "$key" --slurpfile value "$temp_item" '. + {($key): $value[0]}' > "$temp_chunk"
        current_chunk=$(cat "$temp_chunk")
        
        items_in_chunk=$((items_in_chunk + 1))
        
        # Check if chunk is full
        if [ "$items_in_chunk" -ge "$STREAM_CHUNK_SIZE" ]; then
            # Save current chunk
            local chunk_file="$output_dir/${base_name}-chunk-${chunk_num}.json"
            echo "$current_chunk" > "$chunk_file"
            echo "::notice title=Chunk Created::📦 Created chunk $chunk_num with $items_in_chunk items"
            
            # Reset for next chunk
            current_chunk="{}"
            items_in_chunk=0
            chunk_num=$((chunk_num + 1))
        fi
        
        rm -f "$temp_item" "$temp_chunk"
    done < "$keys_file"
    
    # Save final chunk if it has items
    if [ "$items_in_chunk" -gt 0 ]; then
        local chunk_file="$output_dir/${base_name}-chunk-${chunk_num}.json"
        echo "$current_chunk" > "$chunk_file"
        echo "::notice title=Final Chunk::📦 Created final chunk $chunk_num with $items_in_chunk items"
    fi
    
    rm "$keys_file"
    
    # Create index file
    local index_file="$output_dir/${base_name}-index.json"
    jq -n \
        --arg total_chunks "$chunk_num" \
        --arg total_items "$(jq 'keys | length' "$input_file")" \
        --arg chunk_size "$STREAM_CHUNK_SIZE" \
        '{
            processing_mode: "streaming",
            total_chunks: ($total_chunks | tonumber),
            total_items: ($total_items | tonumber),
            chunk_size: ($chunk_size | tonumber),
            chunks: [range(1; ($total_chunks | tonumber) + 1) | "'"${base_name}"'-chunk-\(.).json"]
        }' > "$index_file"
    
    echo "::notice title=Stream Complete::✅ Streaming processing completed: $chunk_num chunks created"
}

# Main processing function with streaming support
process_with_streaming() {
    local input_file="$1"
    local output_path="$2"
    local include_metadata="$3"
    local config="$4"
    local format="${5:-json}"
    
    if needs_streaming "$input_file"; then
        echo "::warning title=Large File::🌊 File requires streaming processing"
        
        # Create streaming output directory
        local output_dir
        output_dir=$(dirname "$output_path")
        local base_name
        base_name=$(basename "$output_path" ".${format}")
        local streaming_dir="${output_dir}/${base_name}-streaming"
        
        # Process in streaming mode
        stream_process_object "$input_file" "$streaming_dir" "$base_name"
        
        # Create summary file at original output path
        create_streaming_summary "$streaming_dir" "$output_path" "$include_metadata" "$config" "$format"
        
        # Compress streaming directory
        tar -czf "${streaming_dir}.tar.gz" -C "$output_dir" "$(basename "$streaming_dir")"
        rm -rf "$streaming_dir"
        
        echo "::notice title=Streaming Archive::📦 Full streaming data archived as: $(basename "${streaming_dir}.tar.gz")"
        
    else
        echo "::notice title=Standard Processing::✅ File size allows standard processing"
        # Use the standard file-based processing from Option 1
        if [ "$include_metadata" = "true" ]; then
            local temp_metadata
            temp_metadata=$(mktemp)
            cat > "$temp_metadata" << EOF
{
  "metadata": {
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "configuration": "$config",
    "processing_mode": "standard"
  }
}
EOF
            
            if [ "$format" = "yaml" ]; then
                jq -s '.[0] + {"terraform_output": .[1]}' "$temp_metadata" "$input_file" | yq eval -P '.' > "$output_path"
            else
                jq -s '.[0] + {"terraform_output": .[1]}' "$temp_metadata" "$input_file" > "$output_path"
            fi
            rm "$temp_metadata"
        else
            if [ "$format" = "yaml" ]; then
                jq '.' "$input_file" | yq eval -P '.' > "$output_path"
            else
                jq '.' "$input_file" > "$output_path"
            fi
        fi
    fi
}

# Create summary for streaming processing
create_streaming_summary() {
    local streaming_dir="$1"
    local output_path="$2"
    local include_metadata="$3"
    local config="$4"
    local format="$5"
    
    local index_file="$streaming_dir/$(basename "$output_path" ".${format}")-index.json"
    
    if [ "$include_metadata" = "true" ]; then
        local summary
        summary=$(jq -n \
            --argjson index "$(cat "$index_file")" \
            --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
            --arg configuration "$config" \
            --arg format "$format" \
            '{
                metadata: {
                    generated_at: $timestamp,
                    configuration: $configuration,
                    export_format: $format,
                    processing_mode: "streaming",
                    note: "Large dataset processed in streaming mode. See compressed archive for full data."
                },
                streaming_info: $index,
                terraform_output: {
                    summary: "Data too large for single file - processed in streaming chunks",
                    access_method: "Download and extract the streaming archive",
                    total_items: $index.total_items,
                    total_chunks: $index.total_chunks
                }
            }')
    else
        local summary
        summary=$(cat "$index_file")
    fi
    
    if [ "$format" = "yaml" ]; then
        echo "$summary" | yq eval -P '.' > "$output_path"
    else
        echo "$summary" > "$output_path"
    fi
}

# Script entry point
if [ $# -lt 4 ] || [ $# -gt 5 ]; then
    echo "Usage: $0 <input_file> <output_file> <include_metadata> <config> [format]"
    exit 1
fi

process_with_streaming "$1" "$2" "$3" "$4" "${5:-json}"
