class QuizScore {
  final int? id;
  final int userId;
  final String userName;
  final int score;
  final String category;
  final int wordsCompleted;
  final int totalAttempts;
  final int correctAttempts;
  final double accuracy;
  final int comboCount;
  final DateTime createdAt;

  const QuizScore({
    this.id,
    required this.userId,
    this.userName = '',
    required this.score,
    required this.category,
    this.wordsCompleted = 0,
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.accuracy = 0,
    this.comboCount = 0,
    required this.createdAt,
  });

  factory QuizScore.fromMap(Map<String, dynamic> map) => QuizScore(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    userName: (map['username'] ?? map['full_name'] ?? map['user_name'] ?? '') as String,
    score: map['score'] as int,
    category: map['category'] as String,
    wordsCompleted: map['words_completed'] as int? ?? 0,
    totalAttempts: map['total_attempts'] as int? ?? 0,
    correctAttempts: map['correct_attempts'] as int? ?? 0,
    accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
    comboCount: map['combo_count'] as int? ?? 0,
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'user_name': userName,
    'score': score,
    'category': category,
    'words_completed': wordsCompleted,
    'total_attempts': totalAttempts,
    'correct_attempts': correctAttempts,
    'accuracy': accuracy,
    'combo_count': comboCount,
    'created_at': createdAt.toIso8601String(),
  };
}
