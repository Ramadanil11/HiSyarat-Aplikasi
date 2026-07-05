import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/quiz_word.dart';
import '../../../services/camera/bisindo_alphabet_data.dart';

class QuizService {
  static const _wordsPath = 'assets/data/quiz_words.json';

  Map<String, List<String>>? _allWords;
  final _random = Random();

  final String category;
  final int timeLimitSeconds;

  QuizService({required this.category})
      : timeLimitSeconds = category == 'easy'
          ? 120
          : category == 'medium'
          ? 90
          : 60;

  static const Duration letterCooldown = Duration(milliseconds: 1000);

  Future<void> loadWords() async {
    if (_allWords != null) return;
    final jsonString = await rootBundle.loadString(_wordsPath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    _allWords = data.map(
      (key, value) => MapEntry(key, List<String>.from(value as List)),
    );
  }

  List<QuizWord> getWordsForCategory() {
    if (_allWords == null) return [];
    final words = _allWords![category] ?? [];
    return words.map((w) => QuizWord(word: w, category: category)).toList();
  }

  QuizWord getRandomWord() {
    final words = getWordsForCategory();
    return words[_random.nextInt(words.length)];
  }

  String getHint(String letter) {
    final gesture = BisindoAlphabetData.getByLetter(letter);
    return gesture?.description ?? 'Isyarat BISINDO untuk huruf $letter';
  }

  int calculateScore({
    required int wordsCompleted,
    required int totalAttempts,
    required int correctAttempts,
    required int remainingSeconds,
    required int comboCount,
  }) {
    if (wordsCompleted == 0) return 0;

    const basePerWord = 10;
    const perfectBonus = 5;
    const speedBonus = 5;
    const comboBonus = 3;

    var score = 0;

    score += wordsCompleted * basePerWord;

    final accuracy = totalAttempts > 0 ? correctAttempts / totalAttempts : 1.0;
    score += (accuracy * 100).round();

    if (accuracy >= 0.8) {
      score += wordsCompleted * perfectBonus;
    }

    if (remainingSeconds > timeLimitSeconds ~/ 2) {
      score += speedBonus;
    }

    score += (comboCount ~/ 5) * comboBonus;

    return score;
  }
}
