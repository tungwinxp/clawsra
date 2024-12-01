#!/bin/bash

# Check if an argument is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <SRR_ID or Bioproject_ID>"
    exit 1
fi

SRA="$1"
OUTPUT_FILE="${SRA}_SRR_Acc_List.txt"

# Check if $SRA already contains "RR"
if [[ $SRA == *RR* ]]; then
    echo "$SRA" > "$OUTPUT_FILE"
    echo "Input $SRA already contains 'RR'. Output written to $OUTPUT_FILE."
    exit 0
fi

echo "Getting all SRR/ERR/DRR from NCBI ID (SRP or Bioproject, etc.) $SRA"

# Fetch and process SRR/ERR/DRR accessions
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=sra&term=${SRA}&retmode=xml&usehistory=y" \
| xmllint --xpath "concat(//QueryKey, ' ', //WebEnv)" - \
| awk '{print "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=sra&query_key="$1"&WebEnv="$2"&rettype=runinfo&retmax=1000000000"}' \
| xargs curl -s -o ${SRA}_RunInfo.xml

if [[ $? -ne 0 ]]; then
    echo "Failed to fetch SRR/ERR/DRR accessions. Please check the SRA ID."
    exit 1
fi

# Extract the raw Run IDs from the XML file
${SRA}_RunInfo.xml | grep \<Run\> | grep "<Run>" | sed 's/.*<Run>\(.*\)<\/Run>.*/\1/' >| $OUTPUT_FILE


# Validate output
if [[ -s "$OUTPUT_FILE" ]]; then
    echo "Process completed successfully."
else
    echo "No valid accessions containing 'RR' found for $SRA. Output may be empty."
    exit 1
fi
