import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  IconData _iconFor(String code) {
    switch (code) {
      case 'beginner_signer': return Icons.star;
      case 'fast_signer': return Icons.bolt;
      case 'perfect_signer': return Icons.auto_awesome;
      case 'quiz_master': return Icons.menu_book;
      case 'bisindo_legend': return Icons.emoji_events;
      default: return Icons.workspace_premium;
    }
  }

  Color _colorFor(String code) {
    switch (code) {
      case 'beginner_signer': return Colors.green;
      case 'fast_signer': return Colors.orange;
      case 'perfect_signer': return Colors.purple;
      case 'quiz_master': return Colors.blue;
      case 'bisindo_legend': return Colors.amber;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AchievementService.getAchievementName(achievement.code);
    final desc = AchievementService.getAchievementDescription(achievement.code);
    final color = _colorFor(achievement.code);
    final icon = _iconFor(achievement.code);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            '${achievement.unlockedAt.day}/${achievement.unlockedAt.month}/${achievement.unlockedAt.year}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
