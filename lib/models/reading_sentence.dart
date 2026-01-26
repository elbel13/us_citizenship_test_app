/// Model representing a sentence for reading practice
class ReadingSentence {
  final String id;
  final String text;
  final List<String> vocabularyWords;
  final String category;
  final int difficulty; // 1-3, where 1 is easiest

  ReadingSentence({
    required this.id,
    required this.text,
    required this.vocabularyWords,
    required this.category,
    this.difficulty = 1,
  });

  factory ReadingSentence.fromJson(Map<String, dynamic> json) {
    return ReadingSentence(
      id: json['id'] as String,
      text: json['text'] as String,
      vocabularyWords: (json['vocabularyWords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      category: json['category'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'vocabularyWords': vocabularyWords,
      'category': category,
      'difficulty': difficulty,
    };
  }

  @override
  String toString() => 'ReadingSentence(id: $id, text: $text)';
}
