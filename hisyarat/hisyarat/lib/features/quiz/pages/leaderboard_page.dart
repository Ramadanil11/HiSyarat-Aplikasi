import 'package:flutter/material.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_card.dart';
import '../models/quiz_score.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _provider = LeaderboardProvider();

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onChanged);
    _provider.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: _provider.loading
          ? const Center(child: CircularProgressIndicator())
          : _provider.scores.isEmpty
              ? const Center(child: Text('Belum ada skor'))
              : ListView.builder(
                  itemCount: _provider.scores.length,
                  itemBuilder: (_, i) => LeaderboardCard(
                    rank: i + 1,
                    score: _provider.scores[i],
                  ),
                ),
    );
  }
}
