import 'package:flutter/material.dart';
import '../models/quiz_score.dart';
import '../services/quiz_service.dart';
import '../services/quiz_score_service.dart';
import '../widgets/leaderboard_card.dart';
import 'quiz_page.dart';
import 'leaderboard_page.dart';
import 'achievement_page.dart';

class QuizMenuPage extends StatefulWidget {
  const QuizMenuPage({super.key});

  @override
  State<QuizMenuPage> createState() => _QuizMenuPageState();
}

class _QuizMenuPageState extends State<QuizMenuPage> {
  final _scoreService = QuizScoreService();
  List<QuizScore> _topScores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await _scoreService.getTopScores(limit: 5);
    if (mounted) setState(() { _topScores = scores; _loading = false; });
  }

  void _startQuiz(String category) {
    final service = QuizService(category: category);
    final timeLimit = service.timeLimitSeconds;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(category: category, timeLimitSeconds: timeLimit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz BISINDO')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Tingkat Kesulitan',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _difficultyCard('Easy', '120 detik', '3-5 huruf', Colors.green, () => _startQuiz('easy')),
            const SizedBox(height: 12),
            _difficultyCard('Medium', '90 detik', '6-8 huruf', Colors.orange, () => _startQuiz('medium')),
            const SizedBox(height: 12),
            _difficultyCard('Hard', '60 detik', '9+ huruf', Colors.red, () => _startQuiz('hard')),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.leaderboard),
                  tooltip: 'Leaderboard',
                  onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.emoji_events),
                  tooltip: 'Achievement',
                  onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AchievementPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Papan Skor',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_topScores.isEmpty)
              const Text('Belum ada skor', textAlign: TextAlign.center)
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _topScores.length,
                  itemBuilder: (_, i) => LeaderboardCard(
                    rank: i + 1,
                    score: _topScores[i],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _difficultyCard(String title, String time, String desc, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    title[0],
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('$time - $desc'),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
