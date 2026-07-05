import 'package:flutter/material.dart';
import '../models/quiz_score.dart';

class LeaderboardCard extends StatelessWidget {
  final int rank;
  final QuizScore score;
  final bool isCurrentUser;

  const LeaderboardCard({
    super.key,
    required this.rank,
    required this.score,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrentUser ? Colors.blue : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('$rank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.amber : Colors.grey)),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: rank <= 3 ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
            child: Icon(Icons.person, size: 18, color: rank <= 3 ? Colors.amber : Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.userName.isNotEmpty ? score.userName : 'User #${score.userId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${score.wordsCompleted} kata \u2022 ${score.accuracy.toStringAsFixed(0)}% akurasi', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('${score.score}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }
}
