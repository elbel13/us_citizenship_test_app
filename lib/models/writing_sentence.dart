/// Model representing a writing practice sentence
class WritingSentence {
  final String id;
  final String text;
  final List<String> vocabularyWords;
  final String category;
  final int difficulty;

  WritingSentence({
    required this.id,
    required this.text,
    required this.vocabularyWords,
    required this.category,
    required this.difficulty,
  });

  factory WritingSentence.fromJson(Map<String, dynamic> json) {
    return WritingSentence(
      id: json['id'] as String,
      text: json['text'] as String,
      vocabularyWords: (json['vocabularyWords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
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
}
