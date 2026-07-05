class Achievement {
  final int? id;
  final int userId;
  final String code;
  final DateTime unlockedAt;

  const Achievement({
    this.id,
    required this.userId,
    required this.code,
    required this.unlockedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    code: map['code'] as String,
    unlockedAt: DateTime.tryParse(map['unlocked_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'code': code,
    'unlocked_at': unlockedAt.toIso8601String(),
  };
}
