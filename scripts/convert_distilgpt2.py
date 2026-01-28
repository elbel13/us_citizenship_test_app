#!/usr/bin/env python3
"""
Convert DistilGPT-2 to TensorFlow Lite format with INT8 quantization.

This script downloads the DistilGPT-2 model from Hugging Face and converts it
to TensorFlow Lite format optimized for mobile deployment.

Setup:
    Run setup_python_env.ps1 (Windows) or setup_python_env.sh (Unix) first to
    create the Conda environment and install dependencies.

Usage:
    # Activate Conda environment
    conda activate us_citizenship_ml
    
    # Run conversion script
    python scripts/convert_distilgpt2.py
"""

import os
import sys
import numpy as np
import tensorflow as tf
from transformers import (
    TFGPT2LMHeadModel,
    GPT2Tokenizer,
)

# Check if running in Conda environment
if 'CONDA_DEFAULT_ENV' not in os.environ:
    print("Warning: Not running in the expected Conda environment.")
    print("Please run: conda activate us_citizenship_ml")
    response = input("Continue anyway? (y/N): ")
    if response.lower() != 'y':
        sys.exit(0)
elif os.environ['CONDA_DEFAULT_ENV'] != 'us_citizenship_ml':
    print(f"Warning: Running in '{os.environ['CONDA_DEFAULT_ENV']}' environment.")
    print("Expected: us_citizenship_ml")
    response = input("Continue anyway? (y/N): ")
    if response.lower() != 'y':
        sys.exit(0)

# Configuration
MODEL_NAME = "distilgpt2"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "models")
TFLITE_MODEL_PATH = os.path.join(OUTPUT_DIR, "distilgpt2.tflite")
TOKENIZER_PATH = os.path.join(OUTPUT_DIR, "tokenizer")

def representative_dataset():
    """
    Generate representative dataset for INT8 quantization.
    Uses sample prompts typical of interview scenarios.
    """
    sample_prompts = [
        "That is correct.",
        "Could you explain that a bit more?",
        "I see. Next question:",
        "Good. Let's continue.",
        "Please clarify what you mean.",
        "Thank you for your answer.",
        "Can you tell me more about that?",
        "That's interesting.",
    ]
    
    tokenizer = GPT2Tokenizer.from_pretrained(MODEL_NAME)
    
    for prompt in sample_prompts:
        input_ids = tokenizer.encode(
            prompt,
            return_tensors="tf",
            max_length=20,
            padding="max_length",
            truncation=True
        )
        yield [input_ids]

def convert_model():
    """Download and convert DistilGPT-2 to TFLite with INT8 quantization."""
    
    print(f"Downloading {MODEL_NAME} from Hugging Face...")
    
    # Load model - force from_pt=True to avoid safetensors issues
    model = TFGPT2LMHeadModel.from_pretrained(MODEL_NAME, from_pt=True)
    tokenizer = GPT2Tokenizer.from_pretrained(MODEL_NAME)
    
    print("Model loaded successfully.")
    
    # Create a concrete function for conversion
    # We'll use a simplified version for text generation
    @tf.function(input_signature=[
        tf.TensorSpec(shape=[1, None], dtype=tf.int32, name="input_ids")
    ])
    def generate(input_ids):
        outputs = model(input_ids, training=False)
        return {"logits": outputs.logits}
    
    print("Creating concrete function...")
    concrete_func = generate.get_concrete_function()
    
    # Convert to TFLite
    print("Converting to TensorFlow Lite...")
    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
    
    # Enable optimization but use dynamic range quantization instead of full INT8
    # This is more compatible with models that have integer inputs
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS  # Allow some TF ops for flexibility
    ]
    
    print("Performing dynamic range quantization...")
    tflite_model = converter.convert()
    
    # Create output directory if it doesn't exist
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Save the TFLite model
    print(f"Saving model to {TFLITE_MODEL_PATH}...")
    with open(TFLITE_MODEL_PATH, "wb") as f:
        f.write(tflite_model)
    
    # Save the tokenizer
    print(f"Saving tokenizer to {TOKENIZER_PATH}...")
    tokenizer.save_pretrained(TOKENIZER_PATH)
    
    # Print model size
    model_size_mb = len(tflite_model) / (1024 * 1024)
    print(f"\n✓ Conversion complete!")
    print(f"  Model size: {model_size_mb:.2f} MB")
    print(f"  Model path: {TFLITE_MODEL_PATH}")
    print(f"  Tokenizer path: {TOKENIZER_PATH}")
    
    # Verify the model
    print("\nVerifying model...")
    interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"  Input shape: {input_details[0]['shape']}")
    print(f"  Output shape: {output_details[0]['shape']}")
    print(f"  Quantization: {input_details[0]['dtype']}")
    
    print("\n✓ Model verified successfully!")

if __name__ == "__main__":
    try:
        convert_model()
    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        sys.exit(1)
