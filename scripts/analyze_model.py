"""Analyze what ops are used in the TFLite model."""
import tensorflow as tf
import json

def analyze_model():
    try:
        # Load the model
        with open("assets/models/distilgpt2.tflite", "rb") as f:
            model_content = f.read()
        
        # Parse with flatbuffers to get op codes
        interpreter = tf.lite.Interpreter(model_path="assets/models/distilgpt2.tflite")
        
        # Get model details
        print("Model loaded successfully")
        print(f"Model size: {len(model_content) / (1024*1024):.2f} MB")
        
        # Try to allocate tensors
        try:
            interpreter.allocate_tensors()
            print("✓ Model can allocate tensors")
        except Exception as e:
            print(f"✗ Error allocating tensors: {e}")
            return
        
        # Get tensor details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print(f"\nInput tensors: {len(input_details)}")
        for detail in input_details:
            print(f"  - {detail['name']}: shape={detail['shape']}, dtype={detail['dtype']}")
        
        print(f"\nOutput tensors: {len(output_details)}")
        for detail in output_details:
            print(f"  - {detail['name']}: shape={detail['shape']}, dtype={detail['dtype']}")
        
        print("\n✓ Model analysis complete")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    analyze_model()
