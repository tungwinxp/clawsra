#!/bin/bash

# Tung Nguyen
# December 1, 2024
# HOW TO DOWNLOAD SRA TO FASTQs WITH FULL PHRED SCORES
# WITH MINIMAL INSTALL SOFTWARE AND NO LOGIN

# Determine the shell configuration file
if [[ $SHELL == */zsh ]]; then
    SHELL_RC=~/.zshrc
elif [[ $SHELL == */bash ]]; then
    SHELL_RC=~/.bashrc
else
    echo "Unsupported shell. Please use Bash or Zsh."
    exit 1
fi

# Detect OS and select appropriate SRA Toolkit
echo "Detecting OS..."
if [[ "$(uname)" == "Darwin" ]]; then
    OS="mac"
    ARCH="mac-arm64"
elif [[ "$(uname -s)" == "Linux" ]]; then
    OS="linux"
    DISTRO=$(grep -Ei 'ubuntu|debian' /etc/os-release && echo "ubuntu" || echo "centos")
    ARCH="ubuntu64"
    [[ $DISTRO == "centos" ]] && ARCH="centos_linux64"
else
    echo "Unsupported OS. This script supports macOS and Linux."
    exit 1
fi

# Install SRA Toolkit
CLAWSRA_DIR=$PWD
if ! command -v fasterq-dump &> /dev/null; then
    echo "fasterq-dump not found. Installing SRA Toolkit..."
    BIN=~/bin/
    mkdir -p $BIN
    cd $BIN

    LATEST_VERSION=$(curl -s https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/ | grep -oE '[0-9.]+/' | tail -n 1 | tr -d '/')
    curl -O https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${LATEST_VERSION}/sratoolkit.${LATEST_VERSION}-${ARCH}.tar.gz
    tar -xzf sratoolkit.${LATEST_VERSION}-${ARCH}.tar.gz
    
    SRATOOLKIT=$(find $PWD -type d -name "sratoolkit.*-${ARCH}")/bin

    # Enable macOS to use unsigned software w/o admin password
    if [[ "$OS" == "mac" ]]; then
        for FILE in $SRATOOLKIT/*; do
            xattr -d com.apple.quarantine $FILE 2>/dev/null || true
        done
    fi

    # Add SRA Toolkit to PATH permanently
    echo "export PATH=\$PATH:$SRATOOLKIT/" >> $SHELL_RC
    
    # Add SRA Toolkit to PATH for the current session
    export PATH=$PATH:$SRATOOLKIT/

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
cd $CLAWSRA_DIR

for SCRIPT in "${SCRIPTS[@]}"; do
    if ! command -v $SCRIPT &> /dev/null; then
        echo "$SCRIPT not found. Adding ./bin to PATH..."
        MISSING_SCRIPTS=1
    fi
done

# Export clawsra's ./bin to PATH if any script is missing
if [[ $MISSING_SCRIPTS -eq 1 ]]; then
    BIN=$CLAWSRA_DIR/bin/
    chmod +x $BIN/*
    
    # Add ./bin to PATH permanently
    echo "export PATH=\$PATH:$BIN/" >> $SHELL_RC
    
    # Add ./bin to PATH for the current session
    export PATH=$PATH:$BIN/

    echo "./bin added to PATH. Scripts are now executable."
else
    echo "All required scripts (clawsra.sh, id_srr.sh, pull_srr.sh) are available."
fi

# making sure the software can run
source $SHELL_RC
