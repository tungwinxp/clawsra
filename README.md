# clawsra
CLAWSRA
Tung Nguyen

## Overview
clawsra.sh downloads AWS SRA sequencing files and converts them to fastq.gz with full PHRED scores. It supports SRA queries (e.g., BioProject ID) or direct SRR accession lists and optionally creates swarm files for parallel processing.

## Usage
clawsra.sh --sra <SRA Query or SRR Accession List> [--swarm <swarm_file>] [--help]
### Flags
--sra <query or file>: Query (e.g., BioProject ID like PRJNA123456) or a file with SRR accession numbers.
--swarm <file>: (Optional) Writes commands to a swarm file for parallel execution.
--help: Displays this help message.

## Quick Setup
### Install SRA Toolkit
if ! command -v fasterq-dump &> /dev/null; then
    BIN=~/bin; mkdir -p $BIN; cd $BIN
    LATEST=$(curl -s https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/ | grep -oE '[0-9.]+/' | tail -n 1 | tr -d '/')
    curl -O https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/$LATEST/sratoolkit.$LATEST-mac-arm64.tar.gz
    tar -xzf sratoolkit.$LATEST-mac-arm64.tar.gz
    SRATOOLKIT=$PWD/sratoolkit.$LATEST-mac-arm64/bin
    echo "export PATH=\$PATH:$SRATOOLKIT" >> ~/.zshrc && source ~/.zshrc
fi

### Install AWS CLI
if ! command -v aws &> /dev/null; then
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip && ./awscli-bundle/install -b ~/bin/aws
    echo "AWS CLI installed in ~/bin/aws"
fi

### Examples
Download using BioProject ID:

clawsra.sh --sra PRJNA123456
Download using SRR list file:

clawsra.sh --sra my_srr_list.txt
Create and execute a swarm file:

clawsra.sh --sra SRP123456 --swarm my_swarm_file.swarm
Ensure id_srr.sh and pull_srr.sh are in your PATH. For issues, check permissions or dependencies (fasterq-dump, aws, swarm).
