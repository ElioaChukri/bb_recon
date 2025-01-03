#!/bin/bash

# Check if a root directory was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <root_directory>"
    exit 1
fi

output_dir="$HOME/archives"

# Create archives dir if it doesn't exist
if [ ! -d "$output_dir" ]; then
    mkdir "$output_dir"
fi

# Omit trailing slash from root directory variable to specify the archive name
root_name="${1%/}"
root_directory="./targets/$root_name"
archive_name="${root_name}_archive.tar.gz"

# Check if dir exists
if [ ! -d "$root_directory" ]; then
    echo "Error: The specified root directory \"$root_directory\" does not exist."
    exit 1
fi

# Create a .tar.gz archive of everything under root dir
tar --exclude='download_csv.csv' --exclude='recon.log' --ignore-failed-read -czf "$archive_name" -C "$root_directory" .

# Move the archive to the archives directory
mv "$archive_name" "$output_dir"

echo "Archive created: ${output_dir}/${archive_name}"