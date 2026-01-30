import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// GPT-2 Byte-Pair Encoding (BPE) tokenizer
///
/// This tokenizer implements the same BPE algorithm used by OpenAI's GPT-2 model.
/// It can encode any text into token IDs and decode token IDs back to text.
///
/// The tokenizer uses two files from the model:
/// - vocab.json: Maps tokens to their IDs (50,257 tokens)
/// - merges.txt: Defines the BPE merge rules
class GPT2Tokenizer {
  // Token mappings
  Map<String, int>? _encoder;
  Map<int, String>? _decoder;
  Map<String, int>? _bpeRanks;

  // Byte encoder/decoder for handling any UTF-8 text
  late Map<int, String> _byteEncoder;
  late Map<String, int> _byteDecoder;

  // Cache for BPE operations to improve performance
  final Map<String, String> _bpeCache = {};

  bool _isInitialized = false;

  /// Whether the tokenizer has been loaded and is ready to use
  bool get isInitialized => _isInitialized;

  /// Initialize the tokenizer by loading vocab and merge files
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Create byte encoder/decoder
    _byteEncoder = _bytesToUnicode();
    _byteDecoder = _byteEncoder.map((k, v) => MapEntry(v, k));

    // Load vocabulary
    final vocabJson = await rootBundle.loadString(
      'assets/models/tokenizer/vocab.json',
    );
    _encoder = Map<String, int>.from(json.decode(vocabJson));
    _decoder = _encoder!.map((k, v) => MapEntry(v, k));

    // Load BPE merges
    final mergesText = await rootBundle.loadString(
      'assets/models/tokenizer/merges.txt',
    );
    final bpeMerges = mergesText
        .split('\n')
        .skip(1) // Skip header line
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim().split(' '))
        .where((parts) => parts.length == 2)
        .toList();

    _bpeRanks = {
      for (var i = 0; i < bpeMerges.length; i++)
        '${bpeMerges[i][0]} ${bpeMerges[i][1]}': i,
    };

    _isInitialized = true;
  }

  /// Encode text into a list of token IDs
  ///
  /// Example:
  /// ```dart
  /// final tokens = tokenizer.encode("Hello, world!");
  /// // Returns: [15496, 11, 995, 0]
  /// ```
  List<int> encode(String text) {
    if (!_isInitialized) {
      throw StateError('Tokenizer not initialized. Call initialize() first.');
    }

    final tokens = <int>[];

    // Split text into tokens using regex pattern (matches words, numbers, whitespace)
    final pattern = RegExp(
      r"""'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+""",
      unicode: true,
    );

    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final token = match.group(0)!;

      // Convert to bytes
      final tokenBytes = utf8.encode(token);
      final tokenChars = tokenBytes.map((b) => _byteEncoder[b]!).join();

      // Apply BPE
      final bpeToken = _bpe(tokenChars);

      // Convert BPE token to IDs
      for (final bpeSubtoken in bpeToken.split(' ')) {
        tokens.add(_encoder![bpeSubtoken]!);
      }
    }

    return tokens;
  }

  /// Decode a list of token IDs back into text
  ///
  /// Example:
  /// ```dart
  /// final text = tokenizer.decode([15496, 11, 995, 0]);
  /// // Returns: "Hello, world!"
  /// ```
  String decode(List<int> tokens) {
    if (!_isInitialized) {
      throw StateError('Tokenizer not initialized. Call initialize() first.');
    }

    // Convert token IDs to strings
    final text = tokens.map((token) => _decoder![token] ?? '').join();

    // Convert from byte encoding back to UTF-8
    final byteValues = text.runes
        .map((r) => _byteDecoder[String.fromCharCode(r)]!)
        .toList();

    return utf8.decode(byteValues, allowMalformed: true);
  }

  /// Apply Byte-Pair Encoding to a token
  String _bpe(String token) {
    // Check cache first
    if (_bpeCache.containsKey(token)) {
      return _bpeCache[token]!;
    }

    var word = token.split('');
    var pairs = _getPairs(word);

    if (pairs.isEmpty) {
      _bpeCache[token] = token;
      return token;
    }

    while (true) {
      // Find the pair with the lowest rank (highest priority to merge)
      final bigram = pairs.reduce((current, next) {
        final currentRank =
            _bpeRanks!['${current.$1} ${current.$2}'] ??
            double.maxFinite.toInt();
        final nextRank =
            _bpeRanks!['${next.$1} ${next.$2}'] ?? double.maxFinite.toInt();
        return currentRank < nextRank ? current : next;
      });

      final bigramKey = '${bigram.$1} ${bigram.$2}';
      if (!_bpeRanks!.containsKey(bigramKey)) {
        break;
      }

      final first = bigram.$1;
      final second = bigram.$2;
      final newWord = <String>[];
      var i = 0;

      while (i < word.length) {
        final j = word.indexOf(first, i);
        if (j == -1) {
          newWord.addAll(word.sublist(i));
          break;
        }

        newWord.addAll(word.sublist(i, j));
        i = j;

        if (word[i] == first && i < word.length - 1 && word[i + 1] == second) {
          newWord.add(first + second);
          i += 2;
        } else {
          newWord.add(word[i]);
          i += 1;
        }
      }

      word = newWord;
      if (word.length == 1) {
        break;
      } else {
        pairs = _getPairs(word);
      }
    }

    final result = word.join(' ');
    _bpeCache[token] = result;
    return result;
  }

  /// Get all adjacent pairs from a list of characters
  List<(String, String)> _getPairs(List<String> word) {
    final pairs = <(String, String)>[];
    for (var i = 0; i < word.length - 1; i++) {
      pairs.add((word[i], word[i + 1]));
    }
    return pairs;
  }

  /// Create a mapping from bytes to Unicode characters
  /// This allows us to handle any UTF-8 text as a fixed set of characters
  Map<int, String> _bytesToUnicode() {
    // Start with printable ASCII characters
    final bs = <int>[
      ...List.generate(33, (i) => i + 33), // ! to ~
      ...List.generate(94, (i) => i + 33), // ! to ~
      ...List.generate(172, (i) => i + 161), // ¡ to ¬
    ];

    final cs = List<int>.from(bs);
    var n = 0;

    for (var b = 0; b < 256; b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(256 + n);
        n++;
      }
    }

    return {
      for (var i = 0; i < bs.length; i++) bs[i]: String.fromCharCode(cs[i]),
    };
  }

  /// Clear the BPE cache
  /// Call this if memory usage becomes a concern
  void clearCache() {
    _bpeCache.clear();
  }
}
