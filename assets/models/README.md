# Model Assets

This directory contains TensorFlow Lite models used by the application.

## DistilGPT-2

The `distilgpt2.tflite` model file should be placed here after conversion.

### Prerequisites

Install **Miniconda** (recommended) or Anaconda:
- Download from: https://docs.conda.io/en/latest/miniconda.html
- Follow installation instructions for your platform

### Setup (First Time Only)

Create the Conda environment with all dependencies:

**Windows (PowerShell):**
```powershell
.\scripts\setup_python_env.ps1
```

**macOS/Linux:**
```bash
chmod +x scripts/setup_python_env.sh
./scripts/setup_python_env.sh
```

This creates a Conda environment named `us_citizenship_ml` with Python 3.12 and all required dependencies.

### Generating the Model

Once the environment is set up, activate it and run the conversion script:

**All Platforms:**
```bash
conda activate us_citizenship_ml
python scripts/convert_distilgpt2.py
```

This will:
1. Download DistilGPT-2 from Hugging Face (~500MB download)
2. Convert it to TensorFlow Lite format with INT8 quantization
3. Save the model (~20-30MB) and tokenizer files to this directory

When done, deactivate the environment:
```bash
conda deactivate
```

**Note**: The converted model file is not included in version control due to its size. You must generate it locally before building the app.

