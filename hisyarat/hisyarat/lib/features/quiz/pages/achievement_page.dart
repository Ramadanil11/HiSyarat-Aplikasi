import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_card.dart';

class AchievementPage extends StatefulWidget {
  final int? userId;

  const AchievementPage({super.key, this.userId});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  late final AchievementProvider _provider;
  List<Achievement> _achievements = [];

  int get _userId => widget.userId ?? context.read<AuthProvider>().currentUser?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _provider = AchievementProvider();
    _provider.addListener(_onChanged);
    _provider.load(_userId);
  }

  void _onChanged() {
    if (mounted) {
      setState(() {
        _achievements = _provider.achievements;
      });
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onChanged);
    super.dispose();
  }

  bool _isUnlocked(String code) {
    return _achievements.any((a) => a.code == code);
  }

  Achievement? _getAchievement(String code) {
    try {
      return _achievements.firstWhere((a) => a.code == code);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievement')),
      body: _provider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: AchievementService.allAchievements.map((code) {
                if (_isUnlocked(code)) {
                  return AchievementCard(achievement: _getAchievement(code)!);
                }
                return _lockedAchievementCard(code);
              }).toList(),
            ),
    );
  }

  Widget _lockedAchievementCard(String code) {
    final name = AchievementService.getAchievementName(code);
    final desc = AchievementService.getAchievementDescription(code);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Text('Terkunci', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
