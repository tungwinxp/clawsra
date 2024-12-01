#!/bin/bash

# Tung Nguyen
# clawsra
# Task: Pull cloud-based AWS SRA sequencing files and convert them to fastq.gz

# Usage:
# ./clawsra.sh --sra <SRA Query or SRR Accession List> [--swarm]
# Flags:
# --sra <query or file> : (Required) Query to the SRA database (e.g., BioProject ID, Study ID), or a file containing SRR accession numbers.
# --swarm               : (Optional) Create a swarm file with commands and execute it.
# --help                : Display this help message.

# Functions
display_help() {
    echo "clawsra - Pull AWS SRA sequencing files and convert them to fastq.gz"
    echo ""
    echo "Usage: $0 --sra <SRA Query or SRR Accession List> [--swarm]"
    echo ""
    echo "Flags:"
    echo "  --sra <query or file> : (Required) Query to the SRA database (e.g., BioProject ID, Study ID), or a file containing SRR accession numbers."
    echo "  --swarm               : (Optional) Create a swarm file with commands and execute it."
    echo "  --help                : Display this help message."
    exit 0
}

# Check for required tools
check_dependencies() {
    for cmd in "swarm" "sh" "curl" "xmllint" "awk" "grep" "sed"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed. Please install it and try again."
            exit 1
        fi
    done
}

# Initialize variables
SRA_QUERY_OR_FILE=""
SWARM_FLAG=false

# Parse Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sra)
            shift
            if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                SRA_QUERY_OR_FILE="$1"
                shift
            else
                echo "Error: --sra flag requires an argument."
                exit 1
            fi
            ;;
        --swarm)
            SWARM_FLAG=true
            shift
            ;;
        --help)
            display_help
            ;;
        *)
            echo "Unknown option $1. Use --help for usage."
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$SRA_QUERY_OR_FILE" ]]; then
    echo "Error: --sra flag is required. Use --help for usage."
    exit 1
fi

# Determine if SRA_QUERY_OR_FILE is a file or a query
if [[ -f "$SRA_QUERY_OR_FILE" ]]; then
    echo "SRR accession list file provided: $SRA_QUERY_OR_FILE" | tee -a script.log
    SRA_LIST_FILE="$SRA_QUERY_OR_FILE"
else
    echo "Querying SRA database with: $SRA_QUERY_OR_FILE" | tee -a script.log
    sh id_srr.sh "$SRA_QUERY_OR_FILE"

    # Define the expected output file for SRR accessions list
    SRA_LIST_FILE="${SRA_QUERY_OR_FILE}_SRR_Acc_List.txt"

    # Check if the SRR list file was generated
    if [[ ! -f "$SRA_LIST_FILE" ]]; then
        echo "Error: $SRA_LIST_FILE not found. Ensure id_srr.sh generates this file."
        exit 1
    fi
fi

echo "Processing SRR accession list from: $SRA_LIST_FILE" | tee -a script.log

# Check dependencies
check_dependencies

# Handle Swarm Flag
if [[ "$SWARM_FLAG" == true ]]; then
    SWARM_FILE="${SRA_QUERY_OR_FILE}_swarm.sh"

    # Initialize the swarm file
    > "$SWARM_FILE"

    echo "Creating swarm file: $SWARM_FILE" | tee -a script.log

    # Append commands to the swarm file
    while IFS= read -r SRR || [[ -n "$SRR" ]]; do
        # Skip empty lines and comments
        [[ -z "$SRR" || "$SRR" =~ ^# ]] && continue
        echo "sh pull_srr.sh $SRR" >> "$SWARM_FILE"
    done < "$SRA_LIST_FILE"

    echo "Swarm file created successfully: $SWARM_FILE" | tee -a script.log

    # Execute the swarm file with additional options and logging
    echo "Executing swarm with $SWARM_FILE..." | tee -a script.log
    swarm -f "$SWARM_FILE" --time=24:00:00 --mem=4G --jobs=10 &> swarm_execution.log
    SWARM_EXIT_CODE=$?

    if [[ $SWARM_EXIT_CODE -ne 0 ]]; then
        echo "Swarm execution failed with exit code $SWARM_EXIT_CODE. Check swarm_execution.log for details." | tee -a script.log
        exit 1
    else
        echo "Swarm execution completed successfully." | tee -a script.log
    fi
else
    echo "Executing commands directly..." | tee -a script.log
    while IFS= read -r SRR || [[ -n "$SRR" ]]; do
        # Skip empty lines and comments
        [[ -z "$SRR" || "$SRR" =~ ^# ]] && continue
        sh pull_srr.sh "$SRR"
        if [[ $? -ne 0 ]]; then
            echo "Error executing pull_srr.sh for SRR: $SRR" | tee -a script.log
            # Uncomment the next line if you want the script to exit on error
            # exit 1
        fi
    done < "$SRA_LIST_FILE"
    echo "All commands executed successfully." | tee -a script.log
fi
