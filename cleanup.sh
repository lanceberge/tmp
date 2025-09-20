#!/bin/bash

aggregate_data() {
    local idx=0
    local dir="$1"
    local batch_size="$2"
    local filetype="$3"
    local archive_filename="$4"

    # Check if directory exists and is accessible
    if [[ ! -d "$dir" ]]; then
        echo "Error: Directory '$dir' does not exist or is not accessible" >&2
        return 1
    fi

    # Validate filetype is not empty
    if [[ -z "$filetype" ]]; then
        echo "Error: Filetype argument is required (e.g., '*.tar.gz' or '*.tar')" >&2
        return 1
    fi

    # Validate archive_filename is not empty
    if [[ -z "$archive_filename" ]]; then
        echo "Error: Archive filename prefix is required (e.g., 'archive')" >&2
        return 1
    fi

    cd "$dir" || {
        echo "Error: Failed to change to directory '$dir'" >&2
        return 1
    }

    # Find all files of the specified filetype, excluding output archives, and process in batches
    find . -maxdepth 1 -type f -name "$filetype" -not -name "$archive_filename-*.tar" -print0 | xargs -0 -n "$batch_size" | while IFS= read -r files; do
        echo "Processing batch $idx in $(pwd)"

        # Check if output file already exists
        if [[ -f "$archive_filename-$idx.tar" ]]; then
            echo "Error: Output file '$archive_filename-batch-$idx.tar' already exists" >&2
            return 1
        fi

        # Convert space-separated files to an array for safe handling
        read -ra file_array <<<"$files"

        # Create tar archive
        if tar -cf "$archive_filename-$idx.tar" "${file_array[@]}"; then
            # Delete files using the array
            rm -f "${file_array[@]}"
            echo "Created $archive_filename-$idx.tar and deleted original files"
        else
            echo "Error: Failed to create $archive_filename-$idx.tar" >&2
            return 1
        fi
        idx=$((idx + 1))
    done
}

aggregate_data "/Users/lance/src/data_cleanup/data" 10 "*.tar" "archive"
