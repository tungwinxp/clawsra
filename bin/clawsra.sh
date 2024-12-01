#!/bin/bash

# Tung Nguyen
# clawsra
# Task: Pull cloud-based AWS SRA sequencing files and convert them to fastq.gz

# Usage:
# ./clawsra.sh --sra <SRA Query or SRR Accession List> [--swarm <swarm_file>]
# Flags:
# --sra <query or file> : Query to the SRA database (e.g., BioProject ID, Study ID, etc.), or a file containing SRR accession numbers.
# --swarm <file>        : (Optional) Create a swarm file with commands and swarm it.
# --help                : Display this help message.

# Functions
display_help() {
    echo "clawsra - Pull AWS SRA sequencing files and convert them to fastq.gz"
    echo ""
    echo "Usage: $0 --sra <SRA Query or SRR Accession List> [--swarm <swarm_file>]"
    echo ""
    echo "Flags:"
    echo "  --sra <query or file> : Query to the SRA database (e.g., BioProject ID, Study ID), or a file containing SRR accession numbers."
    echo "  --swarm <file>        : (Optional) Create a swarm file with commands and swarm it."
    echo "  --help                : Display this help message."
    exit 0
}

# Check for required tools
check_dependencies() {
    for cmd in "swarm" "sh"; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it and try again."
            exit 1
        fi
    done
}

# Parse Arguments
SRA_QUERY_OR_FILE=""
SWARM_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --sra)
            SRA_QUERY_OR_FILE="$2"
            shift 2 ;;
        --swarm)
            SWARM_FILE="$2"
            shift 2 ;;
        --help)
            display_help ;;
        *)
            echo "Unknown option $1. Use --help for usage."
            exit 1 ;;
    esac
done

# Validate arguments
if [[ -z "$SRA_QUERY_OR_FILE" ]]; then
    echo "Error: --sra flag is required. Use --help for usage."
    exit 1
fi

# Takes a query to generate an SRR accession list or
# you supply that SRR accession list in a text file, 
# each SRR separated by new lines.

if [[ -f "$SRA_QUERY_OR_FILE" ]]; then
    echo "SRR accession list file provided: $SRA_QUERY_OR_FILE"
    SRA_LIST_FILE="$SRA_QUERY_OR_FILE"
else
    echo "Querying SRA database with: $SRA_QUERY_OR_FILE"
    sh id_srr.sh "$SRA_QUERY_OR_FILE"

    # Define the expected output file for SRR accessions list
    SRA_LIST_FILE="${SRA_QUERY_OR_FILE}_SRR_Acc_List.txt"

    # Check if the SRR list file was generated
    if [[ ! -f "$SRA_LIST_FILE" ]]; then
        echo "Error: $SRA_LIST_FILE not found. Ensure id_srr.sh generates this file."
        exit 1
    fi
fi

echo "Processing SRR accession list from: $SRA_LIST_FILE"

# Check if $SWARM_FILE variable is set and the file exists
if [[ -n "$SWARM_FILE" && -f "$SWARM_FILE" ]]; then
    echo "Appending commands to $SWARM_FILE..."
    for SRR in $(cat "$SWARM_FILE"); do
        COMMAND="sh pull_srr.sh $SRR"
        echo "$COMMAND" >> "$SWARM_FILE"
    done
else
    echo "Executing commands directly..."
    for SRR in $(cat "$SWARM_FILE"); do
        COMMAND="sh pull_srr.sh $SRR"
        eval "$COMMAND"
    done
fi

# Swarm the file if the --swarm flag is used
if [[ -n "$SWARM_FILE" ]]; then
    echo "Swarming file: $SWARM_FILE"
    swarm "$SWARM_FILE"
fi

echo "Done."
