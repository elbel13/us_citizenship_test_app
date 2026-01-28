# Setup Conda Environment for Model Conversion
# Usage: .\scripts\setup_python_env.ps1
# Requires: Miniconda or Anaconda installed

$ENV_NAME = "us_citizenship_ml"
$ENV_FILE = "scripts\environment.yml"

Write-Host "Setting up Conda environment for model conversion..." -ForegroundColor Cyan

# Check if Conda is available
try {
    $condaVersion = conda --version 2>&1
    Write-Host "Found: $condaVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Conda not found." -ForegroundColor Red
    Write-Host "Please install Miniconda from: https://docs.conda.io/en/latest/miniconda.html" -ForegroundColor Yellow
    exit 1
}

# Check if environment already exists
$envExists = conda env list | Select-String -Pattern "^$ENV_NAME\s"

if ($envExists) {
    Write-Host "Conda environment '$ENV_NAME' already exists." -ForegroundColor Yellow
    $response = Read-Host "Update it? (Y/n)"
    if ($response.ToLower() -eq 'n') {
        Write-Host "Skipping environment update." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Updating environment from $ENV_FILE..." -ForegroundColor Yellow
    conda env update -n $ENV_NAME -f $ENV_FILE --prune
} else {
    Write-Host "Creating Conda environment from $ENV_FILE..." -ForegroundColor Yellow
    conda env create -f $ENV_FILE
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] Setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To activate the environment, run:" -ForegroundColor Cyan
    Write-Host "  conda activate $ENV_NAME" -ForegroundColor White
    Write-Host ""
    Write-Host "To convert the model, run:" -ForegroundColor Cyan
    Write-Host "  python scripts\convert_distilgpt2.py" -ForegroundColor White
    Write-Host ""
    Write-Host "To deactivate, run:" -ForegroundColor Cyan
    Write-Host "  conda deactivate" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "[ERROR] Environment setup failed." -ForegroundColor Red
    exit 1
}
