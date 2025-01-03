#!/bin/env bash

# This script is used to run the recon.py script on all targets that have a download_csv.csv file in their directory.
# These are the targets that are currently being tracked for changes in their domains.

# Sets the bash options. This script will exit if any command fails, and it will exit if any variable is used before being set.
set -Eeuo pipefail

log_date() {
  echo "----------------------------------------" >> "$DIRECTORY/recon.log"
  echo "Starting recon at $(date)" >> "$DIRECTORY/recon.log"
}

log() {
  echo "Performing recon on $1 at $(date)" | tee "$DIRECTORY/recon.log"
}

log_error() {
  echo "ERROR - $1 at $(date)" | tee "$DIRECTORY/recon.log"
}

# set the directory where the recon.py script is located and where the target directories are located
DIRECTORY="$HOME/recon"
TARGETS_DIR="$HOME/recon/targets"

# check if the recon directory exists, else create it
if [ ! -d "$DIRECTORY" ]; then
  mkdir "$DIRECTORY"
fi

# Change to the recon directory or exit if it doesn't exist
cd "$DIRECTORY" || exit

# Check if the recon.py script exists in the recon directory, else exit
if [ ! -f "recon.py" ]; then
  log_error "recon.py script not found in $DIRECTORY"
  exit 1
fi

# Check if the recon.log file exists in the recon directory, else create it
if [ ! -f "recon.log" ]; then
  touch "recon.log"
fi

all_dirs_empty=true

log_date

# Loop through all directories in the current directory
for dir in "$TARGETS_DIR"/*; do
  if [ -f "${dir}/download_csv.csv" ]; then
    all_dirs_empty=false
    log "$dir"
    ./recon.py "$dir"
  fi
done

if [ "$all_dirs_empty" = true ]; then
  log_error "No targets found"
  exit 1
fi

echo "Recon complete at $(date)" | tee -a "$DIRECTORY/recon.log"