#!/bin/bash
# Setup Conda Environment for Model Conversion
# Usage: ./scripts/setup_python_env.sh
# Requires: Miniconda or Anaconda installed

ENV_NAME="us_citizenship_ml"
ENV_FILE="scripts/environment.yml"

echo "Setting up Conda environment for model conversion..."

# Check if Conda is available
if ! command -v conda &> /dev/null; then
    echo "Error: Conda not found."
    echo "Please install Miniconda from: https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

CONDA_VERSION=$(conda --version)
echo "Found: $CONDA_VERSION"

# Initialize conda for bash (if not already done)
eval "$(conda shell.bash hook)"

# Check if environment already exists
if conda env list | grep -q "^$ENV_NAME "; then
    echo "Conda environment '$ENV_NAME' already exists."
    read -p "Update it? (Y/n): " response
    if [ "$response" = "n" ] || [ "$response" = "N" ]; then
        echo "Skipping environment update."
        exit 0
    fi
    echo "Updating environment from $ENV_FILE..."
    conda env update -n "$ENV_NAME" -f "$ENV_FILE" --prune
else
    echo "Creating Conda environment from $ENV_FILE..."
    conda env create -f "$ENV_FILE"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "[SUCCESS] Setup complete!"
    echo ""
    echo "To activate the environment, run:"
    echo "  conda activate $ENV_NAME"
    echo ""
    echo "To convert the model, run:"
    echo "  python scripts/convert_distilgpt2.py"
    echo ""
    echo "To deactivate, run:"
    echo "  conda deactivate"
else
    echo ""
    echo "[ERROR] Environment setup failed."
    exit 1
fi
