import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementProvider extends ChangeNotifier {
  final AchievementService _service = AchievementService();
  List<Achievement> _achievements = [];
  bool _loading = true;

  List<Achievement> get achievements => _achievements;
  bool get loading => _loading;

  Future<void> load(int userId) async {
    _loading = true;
    notifyListeners();
    _achievements = await _service.getUserAchievements(userId);
    _loading = false;
    notifyListeners();
  }

  Future<void> checkAndUnlock(int userId, {
    required bool completedFirstQuiz,
    required bool hasSpeedBonus,
    required bool hasPerfectAccuracy,
    required int totalWordsCompleted,
    required int totalScore,
  }) async {
    if (completedFirstQuiz) {
      await _service.saveAchievement(Achievement(
        userId: userId, code: 'beginner_signer', unlockedAt: DateTime.now(),
      ));
    }
    if (hasSpeedBonus) {
      await _service.saveAchievement(Achievement(
        userId: userId, code: 'fast_signer', unlockedAt: DateTime.now(),
      ));
    }
    if (hasPerfectAccuracy) {
      await _service.saveAchievement(Achievement(
        userId: userId, code: 'perfect_signer', unlockedAt: DateTime.now(),
      ));
    }
    if (totalWordsCompleted >= 100) {
      await _service.saveAchievement(Achievement(
        userId: userId, code: 'quiz_master', unlockedAt: DateTime.now(),
      ));
    }
    if (totalScore >= 1000) {
      await _service.saveAchievement(Achievement(
        userId: userId, code: 'bisindo_legend', unlockedAt: DateTime.now(),
      ));
    }
    await load(userId);
  }
}
