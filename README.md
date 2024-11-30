   ____ _        ___        __             
  / ___| |      / \ \      / /__ _ __ __ _ 
 | |   | |     / _ \ \ /\ / / __| '__/ _` |
 | |___| |___ / ___ \ V  V /\__ \ | | (_| |
  \____|_____/_/   \_\_/\_/ |___/_|  \__,_|                                           

## Overview
clawsra.sh downloads AWS SRA sequencing files from an SRA query (such as Bioproject) and converts them to fastq.gz with full PHRED scores. It supports SRA queries (e.g., BioProject ID) or direct SRR accession lists and optionally creates swarm files for parallel processing.

## Usage
clawsra.sh --sra <SRA Query or SRR Accession List> [--swarm <swarm_file>] [--help]
### Flags
--sra <query or file>: Query (e.g., BioProject ID like PRJNA123456) or a file with SRR accession numbers.
--swarm <file>: (Optional) Writes commands to a swarm file for parallel execution.
--help: Displays this help message.

## Quick Setup
sh install.sh
It will try to ensure id_srr.sh and pull_srr.sh are in your PATH. For issues, check permissions or dependencies (fasterq-dump, aws, swarm).

### Examples
#### Download using BioProject ID:

clawsra.sh --sra PRJNA123456

#### Download using SRR list file:

clawsra.sh --sra my_srr_list.txt

#### Create and execute a swarm file (for SLURM cluster to run in parallel jobs):

clawsra.sh --sra SRP123456 --swarm my_swarm_file.swarm

