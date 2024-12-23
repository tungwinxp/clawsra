## CLAWSRA
clawsra.sh retrieves sequencing data hosted on AWS by querying the SRA database and identifying Run Accessions (SRR*). It then downloads the corresponding files and converts them to fastq.gz format with full PHRED scores. The script supports both SRA queries (e.g., BioProject IDs, Study IDs) and pre-existing SRR accession lists. Additionally, it can optionally generate swarm files for parallel processing.

## Usage
````
clawsra.sh -q <SRA Query or SRR Accession List> [--swarm <swarm_file>] [--help]
````

### Flags
--sra <query or file>: Query (e.g., BioProject ID like PRJNA123456) or a file with SRR accession numbers.
--swarm <file>: (Optional) Writes commands to a swarm file for parallel execution.
--help: Displays this help message.

## Quick Setup
````
sh install.sh
````
It will try to ensure id_srr.sh and pull_srr.sh are in your PATH. For issues, check permissions or dependencies (fasterq-dump, aws, swarm).

### Examples
#### Download using BioProject ID:
````
clawsra.sh -q PRJNA123456
````

#### Download using SRR list file:
````
clawsra.sh -q my_srr_list.txt
````

#### Create and execute a swarm file (for SLURM cluster to run in parallel jobs):
````
clawsra.sh -q SRP123456 --swarm my_swarm_file.swarm
````


