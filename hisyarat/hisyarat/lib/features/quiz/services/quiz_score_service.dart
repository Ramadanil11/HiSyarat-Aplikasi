import 'package:hisyarat/core/database_helper.dart';
import '../models/quiz_score.dart';

class QuizScoreService {
  final DatabaseHelper _db = DatabaseHelper();

  static const String _table = 'quiz_scores';

  Future<int> saveScore(QuizScore score) async {
    return await _db.insert(_table, score.toMap());
  }

  Future<List<QuizScore>> getTopScores({int limit = 10}) async {
    final rows = await _db.rawQuery('''
      SELECT q.*, COALESCE(u.username, u.full_name, 'User #' || q.user_id) as username
      FROM $_table q
      LEFT JOIN users u ON q.user_id = u.id
      ORDER BY q.score DESC
      LIMIT ?
    ''', [limit]);
    return rows.map((row) => QuizScore.fromMap(row)).toList();
  }

  Future<List<QuizScore>> getUserScores(int userId) async {
    final rows = await _db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => QuizScore.fromMap(row)).toList();
  }

  Future<int> getUserTotalScore(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(score), 0) as total FROM $_table WHERE user_id = ?',
      [userId],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> getUserHighScore(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(MAX(score), 0) as best FROM $_table WHERE user_id = ?',
      [userId],
    );
    return (rows.first['best'] as num?)?.toInt() ?? 0;
  }

  Future<int> getUserTotalWordsCompleted(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(words_completed), 0) as total FROM $_table WHERE user_id = ?',
      [userId],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<double> getUserAverageAccuracy(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(AVG(accuracy), 0) as avg FROM $_table WHERE user_id = ?',
      [userId],
    );
    return (rows.first['avg'] as num?)?.toDouble() ?? 0.0;
  }
}
