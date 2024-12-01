#!/bin/bash

# Check if an argument is provided
if [[ -z "$1" ]]; then
    echo "Usage: $0 <SRR_ID>"
    exit 1
fi

SRA="$1"

echo "Getting all SRR from NCBI ID (SRP or Bioproject, etc.) $SRA"


curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=sra&term=${SRA}&retmode=xml&usehistory=y" \
| xmllint --xpath "concat(//QueryKey, ' ', //WebEnv)" - \
| awk '{print "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=sra&query_key="$1"&WebEnv="$2"&rettype=runinfo"}' \
| xargs curl -s -o ${SRA}_RunInfo.xml && xmllint --xpath "//Run/text()" ${SRA}_RunInfo.xml >| ${SRA}_SRR_Acc_List.txt
