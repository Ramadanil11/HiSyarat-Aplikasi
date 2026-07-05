import 'package:flutter/material.dart';

class ScoreWidget extends StatelessWidget {
  final int score;
  final int comboCount;
  final int wordsCompleted;

  const ScoreWidget({
    super.key,
    required this.score,
    required this.comboCount,
    required this.wordsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _item(Icons.star, 'Skor', '$score'),
        if (comboCount > 0)
          _item(Icons.local_fire_department, 'Combo', '$comboCount'),
        _item(Icons.check_circle_outline, 'Kata', '$wordsCompleted'),
      ],
    );
  }

  Widget _item(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
