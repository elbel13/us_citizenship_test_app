import 'package:flutter_test/flutter_test.dart';
import 'package:us_citizenship_test_app/services/gpt2_tokenizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GPT2Tokenizer', () {
    late GPT2Tokenizer tokenizer;

    setUp(() {
      tokenizer = GPT2Tokenizer();
    });

    test('should initialize successfully', () async {
      await tokenizer.initialize();
      expect(tokenizer.isInitialized, true);
    });

    test('should encode and decode simple text', () async {
      await tokenizer.initialize();

      const text = 'Hello, world!';
      final tokens = tokenizer.encode(text);
      final decoded = tokenizer.decode(tokens);

      expect(decoded, text);
      expect(tokens.isNotEmpty, true);
    });

    test('should encode citizenship-related text', () async {
      await tokenizer.initialize();

      const text = 'What are the three branches of government?';
      final tokens = tokenizer.encode(text);
      final decoded = tokenizer.decode(tokens);

      expect(decoded, text);
      print('Text: "$text"');
      print('Tokens (${tokens.length}): $tokens');
    });

    test('should handle unknown words through BPE', () async {
      await tokenizer.initialize();

      // This word likely isn't in the vocabulary
      const text = 'supercalifragilisticexpialidocious';
      final tokens = tokenizer.encode(text);
      final decoded = tokenizer.decode(tokens);

      expect(decoded, text);
      expect(tokens.length, greaterThan(1)); // Should be split into subwords
      print('Unknown word: "$text"');
      print('Tokens (${tokens.length}): $tokens');
    });

    test('should handle empty string', () async {
      await tokenizer.initialize();

      const text = '';
      final tokens = tokenizer.encode(text);
      final decoded = tokenizer.decode(tokens);

      expect(tokens.isEmpty, true);
      expect(decoded, text);
    });

    test('should handle special characters and emojis', () async {
      await tokenizer.initialize();

      const text = 'Hello 👋 citizenship test!';
      final tokens = tokenizer.encode(text);
      final decoded = tokenizer.decode(tokens);

      expect(decoded, text);
      print('Text with emoji: "$text"');
      print('Tokens (${tokens.length}): $tokens');
    });
  });
}
