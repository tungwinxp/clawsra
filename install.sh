#!/bin/bash

# Tung Nguyen
# November 28 2024
# HOW TO DOWNLOAD SRA TO FASTQs WITH FULL PHRED SCORES
# WITH MINIMAL INSTALL SOFTWARE AND NO LOGIN

## EXAMPLE ##
# SRA: SRP526500
# BioProject: PRJNA1148326

# Install SRA Toolkit into ~/bin/
if ! command -v fasterq-dump &> /dev/null; then
    echo "fasterq-dump not found. Installing SRA Toolkit..."
    
    BIN=~/bin
    mkdir -p $BIN
    cd $BIN
    
    LATEST_VERSION=$(curl -s https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/ | grep -oE '[0-9.]+/' | tail -n 1 | tr -d '/')
    curl -O https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/$LATEST_VERSION/sratoolkit.${LATEST_VERSION}-mac-arm64.tar.gz
    tar -xzf sratoolkit.${LATEST_VERSION}-mac-arm64.tar.gz
    
    cd sratoolkit.${LATEST_VERSION}-mac-arm64/bin
    SRATOOLKIT=$PWD

    # Enable Mac to use unsigned software w/o admin pswd.
    for FILE in *; do
        xattr -d com.apple.quarantine $FILE 2>/dev/null || true
    done
    
    # Add SRA Toolkit to PATH permanently
    echo "export PATH=\$PATH:$SRATOOLKIT" >> ~/.zshrc
    
    # Add SRA Toolkit to PATH for the current session
    export PATH=$PATH:$SRATOOLKIT

    echo "SRA Toolkit installed and added to PATH."
else
    echo "fasterq-dump is already installed and available."
fi

# Install AWS CLI into ~/bin/
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Installing..."
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    ./awscli-bundle/install -b ~/bin/aws
    echo "AWS CLI installed at ~/bin/aws"
else
    echo "AWS CLI is already installed."
fi

# Check for clawsra.sh, id_srr.sh, and pull_srr.sh
SCRIPTS=("clawsra.sh" "id_srr.sh" "pull_srr.sh")
MISSING_SCRIPTS=0

for SCRIPT in "${SCRIPTS[@]}"; do
    if ! command -v $SCRIPT &> /dev/null; then
        echo "$SCRIPT not found. Adding ./bin to PATH..."
        MISSING_SCRIPTS=1
    fi
done

# Export clawsra's ./bin to PATH if any script is missing
if [[ $MISSING_SCRIPTS -eq 1 ]]; then
    BIN=$PWD/bin
    chmod +x $BIN/*
    
    # Add ./bin to PATH permanently
    echo "export PATH=\$PATH:$BIN" >> ~/.zshrc
    
    # Add ./bin to PATH for the current session
    export PATH=$PATH:$BIN

    echo "./bin added to PATH. Scripts executable now."
else
    echo "All required scripts (clawsra.sh, id_srr.sh, pull_srr.sh) are available."
fi
