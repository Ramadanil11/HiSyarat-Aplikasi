import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../services/quiz_score_service.dart';
import '../services/achievement_service.dart';
import '../models/quiz_score.dart';
import '../providers/achievement_provider.dart';
import 'quiz_menu_page.dart';
import 'quiz_page.dart';
import 'leaderboard_page.dart';
import 'achievement_page.dart';

class QuizResultPage extends StatefulWidget {
  final int score;
  final String category;
  final int wordsCompleted;
  final int totalWords;
  final int totalAttempts;
  final int correctAttempts;
  final int comboCount;
  final int remainingSeconds;
  final int timeLimitSeconds;

  const QuizResultPage({
    super.key,
    required this.score,
    required this.category,
    required this.wordsCompleted,
    required this.totalWords,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.comboCount,
    required this.remainingSeconds,
    required this.timeLimitSeconds,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveAndCheck());
  }

  Future<void> _saveAndCheck() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? 0;
    final userName = authProvider.currentUser?.name ?? '';
    final accuracy = widget.totalAttempts > 0
        ? (widget.correctAttempts / widget.totalAttempts * 100)
        : 0.0;

    final scoreService = QuizScoreService();

    await scoreService.saveScore(QuizScore(
      userId: userId,
      userName: userName,
      score: widget.score,
      category: widget.category,
      wordsCompleted: widget.wordsCompleted,
      totalAttempts: widget.totalAttempts,
      correctAttempts: widget.correctAttempts,
      accuracy: accuracy,
      comboCount: widget.comboCount,
      createdAt: DateTime.now(),
    ));

    final totalWordsCompleted = await scoreService.getUserTotalWordsCompleted(userId);
    final totalScore = await scoreService.getUserTotalScore(userId);

    final achievementProvider = AchievementProvider();
    await achievementProvider.checkAndUnlock(
      userId,
      completedFirstQuiz: true,
      hasSpeedBonus: widget.remainingSeconds > widget.timeLimitSeconds ~/ 2,
      hasPerfectAccuracy: accuracy >= 100,
      totalWordsCompleted: totalWordsCompleted,
      totalScore: totalScore,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.totalAttempts > 0
        ? (widget.correctAttempts / widget.totalAttempts * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Quiz'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Skor Akhir',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.score}',
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _resultRow('Kategori', widget.category.toUpperCase()),
              _resultRow('Kata selesai', '${widget.wordsCompleted}/${widget.totalWords}'),
              _resultRow('Akurasi', '$accuracy%'),
              _resultRow('Percobaan', '${widget.totalAttempts}'),
              _resultRow('Combo', '${widget.comboCount}'),
              _resultRow('Sisa waktu', '${widget.remainingSeconds}s'),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPage(
                        category: widget.category,
                        timeLimitSeconds: widget.timeLimitSeconds,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.replay),
                label: const Text('Coba Lagi'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizMenuPage()),
                    (route) => false,
                  );
                },
                child: const Text('Kembali ke Menu'),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                      );
                    },
                    icon: const Icon(Icons.leaderboard, size: 18),
                    label: const Text('Leaderboard'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AchievementPage()),
                      );
                    },
                    icon: const Icon(Icons.emoji_events, size: 18),
                    label: const Text('Achievement'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
