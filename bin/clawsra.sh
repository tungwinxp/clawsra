#!/bin/bash

# Tung Nguyen
# clawsra
# Task: Pull cloud-based AWS SRA sequencing files and convert them to fastq.gz

# Usage:
# ./clawsra.sh -s <SRA Query or SRR Accession List> [-w]
# Flags:
# -s <query or file> : (Required) Query to the SRA database (e.g., BioProject ID, Study ID), or a file containing SRR accession numbers.
# -w                 : (Optional) Create a swarm file with commands and execute it.
# -h                 : Display this help message.

# Functions
display_help() {
    echo "clawsra - Pull AWS SRA sequencing files and convert them to fastq.gz"
    echo ""
    echo "Usage: $0 -q <SRA Query or SRR Accession List> [-w]"
    echo ""
    echo "Flags:"
    echo "  -q <query or file> : (Required) Query to the SRA database (e.g., BioProject ID, Study ID), or a file containing SRR accession numbers."
    echo "  -w                 : (Optional) Create a swarm file with commands and execute it."
    echo "  -h                 : Display this help message."
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

# Parse Arguments using getopts
while getopts ":q:wh" opt; do
    case ${opt} in
        q )
            SRA_QUERY_OR_FILE="$OPTARG"
            ;;
        w )
            SWARM_FLAG=true
            ;;
        h )
            display_help
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" >&2
            echo "Use -h for help."
            exit 1
            ;;
        : )
            echo "Invalid Option: -$OPTARG requires an argument" >&2
            echo "Use -h for help."
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Ensure no positional arguments are provided
if [[ $# -gt 0 ]]; then
    echo "Error: Unexpected positional arguments detected. Use flags only. Use -h for help."
    exit 1
fi

# Validate required arguments
if [[ -z "$SRA_QUERY_OR_FILE" ]]; then
    echo "Error: -q flag is required. Use -h for help."
    exit 1
fi

# Determine if SRA_QUERY_OR_FILE is a file or a query
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

# Check dependencies
check_dependencies

# Handle Swarm Flag
if [[ "$SWARM_FLAG" == true ]]; then
    SWARM_FILE="${SRA_QUERY_OR_FILE}_swarm.sh"

    # Initialize the swarm file
    echo "#SWARM --logdir /data/user/swarmlogs" >| "$SWARM_FILE"

    echo "Creating swarm file: $SWARM_FILE"

    # Append commands to the swarm file
    while IFS= read -r SRR || [[ -n "$SRR" ]]; do
        # Skip empty lines and comments
        [[ -z "$SRR" ]] && continue
        echo "sh pull_srr.sh $SRR" >> "$SWARM_FILE"
    done < "$SRA_LIST_FILE"

    echo "Swarm file created successfully: $SWARM_FILE"

    # Execute the swarm file with additional options and logging
    echo "Executing swarm with $SWARM_FILE..."
    swarm -f "$SWARM_FILE" --time=24:00:00
    SWARM_EXIT_CODE=$?

else
    echo "Executing commands directly..."
    while IFS= read -r SRR || [[ -n "$SRR" ]]; do
        # Skip empty lines and comments
        [[ -z "$SRR" ]] && continue
        sh pull_srr.sh "$SRR"
        if [[ $? -ne 0 ]]; then
            echo "Error executing pull_srr.sh for SRR: $SRR"
            # Uncomment the next line if you want the script to exit on error
            # exit 1
        fi
    done < "$SRA_LIST_FILE"
    echo "All commands executed successfully."
fi

# TO DO:
# get the LOGAN contig or unitig
# compression
# stream in faster-qdump.
# don't store fastq just start alignment, detect paired end on the correct reference. 
# have a minimap reference, get BAM files and store those for downstream.
