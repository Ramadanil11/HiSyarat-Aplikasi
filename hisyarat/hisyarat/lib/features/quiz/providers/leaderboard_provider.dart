import 'package:flutter/foundation.dart';
import '../models/quiz_score.dart';
import '../services/quiz_score_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final QuizScoreService _scoreService = QuizScoreService();
  List<QuizScore> _scores = [];
  bool _loading = true;

  List<QuizScore> get scores => _scores;
  bool get loading => _loading;

  Future<void> load({int limit = 20}) async {
    _loading = true;
    notifyListeners();
    _scores = await _scoreService.getTopScores(limit: limit);
    _loading = false;
    notifyListeners();
  }
}
