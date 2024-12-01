#!/bin/bash

# Check if an argument is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <SRR_ID>"
    exit 1
fi

# Get the SRR ID from the first argument
file="$1"

# Main processing steps
echo "Processing SRR: $file"

mkdir -p tmp_aws/ fastq/

# Sync the file from S3
aws s3 sync s3://sra-pub-run-odp/sra/$file tmp_aws/$file --no-sign-request && \
echo "$file downloaded successfully."

# fasterq-dump --split-files tmp_aws/$file/$file -O fastq/ && \
# rm -rf tmp_aws/$file && \
# gzip fastq/$file_*.fastq && \
# echo "$file fastq processed successfully."

time fastq-dump --gzip --skip-technical --readids #--read-filter pass \
	--dumpbase --split-files --clip --outdir fastq/ tmp_aws/$file/$file && rm -rf tmp_aws/$file && touch fastq/$file.done

