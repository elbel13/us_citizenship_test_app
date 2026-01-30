"""
Convert DistilGPT-2 to TensorFlow Lite without SELECT_TF_OPS.

This attempts to create a model that only uses standard TFLite ops,
which are more widely supported on mobile platforms.
"""

import os
import tensorflow as tf
from transformers import TFGPT2LMHeadModel, GPT2Tokenizer

MODEL_NAME = "distilgpt2"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "models")
TFLITE_MODEL_PATH = os.path.join(OUTPUT_DIR, "distilgpt2_builtins_only.tflite")

def convert_model_builtins_only():
    """Convert model using only TFLite builtins."""
    
    print(f"Loading {MODEL_NAME}...")
    model = TFGPT2LMHeadModel.from_pretrained(MODEL_NAME, from_pt=True)
    
    print("Creating concrete function...")
    @tf.function(input_signature=[
        tf.TensorSpec(shape=[1, None], dtype=tf.int32, name="input_ids")
    ])
    def generate(input_ids):
        outputs = model(input_ids, training=False)
        return {"logits": outputs.logits}
    
    concrete_func = generate.get_concrete_function()
    
    # Try conversion with ONLY TFLite builtins
    print("Converting to TensorFlow Lite (builtins only)...")
    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
    
    # Only use TFLite builtins - NO SELECT_TF_OPS
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
    ]
    
    # Enable optimizations
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Experimental options
    converter.experimental_new_converter = True
    converter._experimental_lower_tensor_list_ops = False
    
    try:
        tflite_model = converter.convert()
        
        # Save the model
        print(f"Saving model to {TFLITE_MODEL_PATH}...")
        with open(TFLITE_MODEL_PATH, "wb") as f:
            f.write(tflite_model)
        
        model_size_mb = len(tflite_model) / (1024 * 1024)
        print(f"\n✓ Conversion complete!")
        print(f"  Model size: {model_size_mb:.2f} MB")
        print(f"  Model path: {TFLITE_MODEL_PATH}")
        
        # Verify
        print("\nVerifying model...")
        interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
        interpreter.allocate_tensors()
        
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"  Input shape: {input_details[0]['shape']}")
        print(f"  Output shape: {output_details[0]['shape']}")
        print("\n✓ Model verified!")
        
    except Exception as e:
        print(f"\n✗ Conversion failed: {e}")
        print("\nThis likely means GPT-2 requires SELECT_TF_OPS for some operations.")
        print("The model may not be fully compatible with TFLite builtins only.")

if __name__ == "__main__":
    convert_model_builtins_only()
