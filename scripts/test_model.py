"""Test script to verify TFLite model loads correctly."""
import tensorflow as tf

def test_model():
    try:
        # Try to load the TFLite model
        interpreter = tf.lite.Interpreter(model_path="assets/models/distilgpt2.tflite")
        interpreter.allocate_tensors()

        # Get input and output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        print("✓ Model loaded successfully!")
        print(f"\nInput details ({len(input_details)} inputs):")
        for i, detail in enumerate(input_details):
            print(f"  Input {i}: {detail['name']}")
            print(f"    Shape: {detail['shape']}")
            print(f"    Type: {detail['dtype']}")
            if 'quantization' in detail:
                print(f"    Quantization: {detail['quantization']}")

        print(f"\nOutput details ({len(output_details)} outputs):")
        for i, detail in enumerate(output_details):
            print(f"  Output {i}: {detail['name']}")
            print(f"    Shape: {detail['shape']}")
            print(f"    Type: {detail['dtype']}")
            if 'quantization' in detail:
                print(f"    Quantization: {detail['quantization']}")
        
        return True
    except Exception as e:
        print(f"✗ Error loading model: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_model()
    exit(0 if success else 1)
