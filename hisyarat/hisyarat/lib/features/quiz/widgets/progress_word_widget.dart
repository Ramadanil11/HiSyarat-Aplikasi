import 'package:flutter/material.dart';
import '../../../core/themes.dart';

class ProgressWordWidget extends StatelessWidget {
  final List<String> letters;
  final int currentIndex;
  final String targetLetter;
  final bool onCooldown;

  const ProgressWordWidget({
    super.key,
    required this.letters,
    required this.currentIndex,
    required this.targetLetter,
    this.onCooldown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Tunjukkan Huruf', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        AnimatedScale(
          scale: onCooldown ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onCooldown ? Colors.green : AppColors.primary, width: 2),
            ),
            child: Center(
              child: onCooldown
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
                  : Text(
                      targetLetter,
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(letters.length, (i) {
            final isCompleted = i < currentIndex;
            final isCurrent = i == currentIndex;
            return Container(
              width: 36,
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.2)
                    : isCurrent
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted ? Colors.green : (isCurrent ? AppColors.primary : Colors.grey.shade300),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  isCompleted ? '✓' : letters[i],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : (isCurrent ? AppColors.primary : Colors.grey),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
