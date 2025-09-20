#!/bin/bash

# seq 1 100 | xargs -I{} touch {}.tar
aggregate_data() {
    local idx=0
    local dir="$1"
    local batch_size="$2"
    local filetype="$3"
    local archive_filename="$4"

    # Dir exists
    if [[ ! -d "$dir" ]]; then
        echo "Error: Directory '$dir' does not exist or is not accessible" >&2
        return 1
    fi

    cd "$dir" || {
        echo "Error: Failed to change to directory '$dir'" >&2
        return 1
    }

    find . -maxdepth 1 -type f -name "$filetype" -not -name "$archive_filename-*.tar" -print0 | xargs -0 -n "$batch_size" | while IFS= read -r files; do
        echo "Processing batch $idx in $(pwd)"

        if [[ -f "$archive_filename-$idx.tar" ]]; then
            echo "Error: Output file '$archive_filename-batch-$idx.tar' already exists" >&2
            return 1
        fi

        read -ra file_array <<<"$files"

        # Create tarball
        if tar -cf "$archive_filename-$idx.tar" "${file_array[@]}"; then
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
