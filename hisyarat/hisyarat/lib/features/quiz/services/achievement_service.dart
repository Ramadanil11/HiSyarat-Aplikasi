import 'package:hisyarat/core/database_helper.dart';
import '../models/achievement.dart';

class AchievementService {
  final DatabaseHelper _db = DatabaseHelper();

  static const String _table = 'achievements';

  static const List<String> allAchievements = [
    'beginner_signer',
    'fast_signer',
    'perfect_signer',
    'quiz_master',
    'bisindo_legend',
  ];

  static String getAchievementName(String code) {
    switch (code) {
      case 'beginner_signer': return 'Beginner Signer';
      case 'fast_signer': return 'Fast Signer';
      case 'perfect_signer': return 'Perfect Signer';
      case 'quiz_master': return 'Quiz Master';
      case 'bisindo_legend': return 'BISINDO Legend';
      default: return code;
    }
  }

  static String getAchievementDescription(String code) {
    switch (code) {
      case 'beginner_signer': return 'Selesaikan quiz pertamamu';
      case 'fast_signer': return 'Selesaikan dengan sisa waktu > 30 detik';
      case 'perfect_signer': return 'Akurasi 100% dalam satu sesi';
      case 'quiz_master': return '100 kata berhasil diselesaikan';
      case 'bisindo_legend': return 'Kumpulkan total 1000 skor';
      default: return '';
    }
  }

  Future<void> saveAchievement(Achievement achievement) async {
    final existing = await _db.query(
      _table,
      where: 'user_id = ? AND code = ?',
      whereArgs: [achievement.userId, achievement.code],
    );
    if (existing.isEmpty) {
      await _db.insert(_table, achievement.toMap());
    }
  }

  Future<bool> hasAchievement(int userId, String code) async {
    final rows = await _db.query(
      _table,
      where: 'user_id = ? AND code = ?',
      whereArgs: [userId, code],
    );
    return rows.isNotEmpty;
  }

  Future<List<Achievement>> getUserAchievements(int userId) async {
    final rows = await _db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'unlocked_at DESC',
    );
    return rows.map((row) => Achievement.fromMap(row)).toList();
  }
}
