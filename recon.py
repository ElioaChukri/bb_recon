#!/usr/bin/python3

import subprocess
import csv
import sys
import os

# Get home directory
home = os.getenv("HOME")
script_path = f"{home}/recon/recon.sh"

if len(sys.argv) != 2:
    print("Usage: ./recon.py <path>")
    sys.exit(1)


def load_csv(file):
    with open(file, 'r') as f:
        reader = csv.DictReader(f)
        return list(reader)


def run_recon(domains, wildcards):
    for wildcard in wildcards:
        subprocess.run([script_path, wildcard, '-p', sys.argv[1]])
    for domain in domains:
        subprocess.run([script_path, domain, '-n', '-p', sys.argv[1]])


def main():
    folder = f"{sys.argv[1]}"
    domains = []
    wildcards = []

    # Load the CSV file
    data = load_csv(f"{folder}/download_csv.csv")

    for row in data:

        if row['eligible_for_bounty'] != "true":
            continue

        asset_type = row['asset_type'].lower()

        if '*' in row['identifier']:
            # Remove everything before the *.
            row['identifier'] = row['identifier'].split('*.')[1]
            wildcards.append(row['identifier'])

        elif asset_type == 'domain' or asset_type == 'url':
            domains.append(row['identifier'])

        elif asset_type == 'wildcard':
            wildcards.append(row['identifier'])
        else:
            continue

    # Write the domains and wildcards to a file
    with open(f"{folder}/domains.txt", 'w') as f:
        for domain in domains:
            f.write(f"{domain}\n")

    with open(f"{folder}/wildcards.txt", 'w') as f:
        for wildcard in wildcards:
            f.write(f"{wildcard}\n")

    # Run the recon script
    run_recon(domains, wildcards)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(" \nScript execution interrupted with CTRL-C. Exiting...")
        sys.exit(0)
