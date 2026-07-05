import 'package:flutter/foundation.dart';
import '../models/quiz_word.dart';
import '../services/quiz_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService service;
  
  List<QuizWord> _words = [];
  int _currentWordIndex = 0;
  int _currentLetterIndex = 0;
  int _wordsCompleted = 0;
  int _totalAttempts = 0;
  int _correctAttempts = 0;
  int _failedAttempts = 0;
  int _comboCount = 0;
  int _score = 0;
  int _remainingSeconds;
  bool _onCooldown = false;
  bool _showingHint = false;
  bool _gameOver = false;
  String? _lastDetectedLetter;
  double _lastConfidence = 0.0;
  String _recognitionMethod = '';
  String _description = '';
  String _status = 'NO HAND';

  QuizProvider({required this.service, required int timeLimit})
      : _remainingSeconds = timeLimit;

  List<QuizWord> get words => _words;
  int get currentWordIndex => _currentWordIndex;
  int get currentLetterIndex => _currentLetterIndex;
  int get wordsCompleted => _wordsCompleted;
  int get totalAttempts => _totalAttempts;
  int get correctAttempts => _correctAttempts;
  int get failedAttempts => _failedAttempts;
  int get comboCount => _comboCount;
  int get score => _score;
  int get remainingSeconds => _remainingSeconds;
  bool get onCooldown => _onCooldown;
  bool get showingHint => _showingHint;
  bool get gameOver => _gameOver;
  String? get lastDetectedLetter => _lastDetectedLetter;
  double get lastConfidence => _lastConfidence;
  String get recognitionMethod => _recognitionMethod;
  String get description => _description;
  String get status => _status;

  String get currentWord => _words.isNotEmpty && _currentWordIndex < _words.length
      ? _words[_currentWordIndex].word : '';
  String get currentTargetLetter => currentWord.isNotEmpty && _currentLetterIndex < currentWord.length
      ? currentWord[currentLetterIndex] : '';
  List<String> get wordLetters => currentWord.split('');
  double get accuracy => _totalAttempts > 0 ? (_correctAttempts / _totalAttempts) * 100 : 0;

  void loadWords(List<QuizWord> words) {
    _words = words..shuffle();
    notifyListeners();
  }

  void onLetterDetected(String letter, double confidence, {String method = '', String description = '', String status = 'NO HAND'}) {
    if (_gameOver || _onCooldown || currentTargetLetter.isEmpty) return;

    _lastDetectedLetter = letter;
    _lastConfidence = confidence;
    _recognitionMethod = method;
    _description = description;
    _status = status;
    _totalAttempts++;

    if (letter == currentTargetLetter) {
      _correctAttempts++;
      _comboCount++;
      _score++;
      _failedAttempts = 0;
      _showingHint = false;
      _startCooldown();

      if (_currentLetterIndex + 1 < currentWord.length) {
        _currentLetterIndex++;
      } else {
        _wordCompleted();
      }
    } else {
      _failedAttempts++;
      _comboCount = 0;
      if (_failedAttempts >= 3) {
        _showingHint = true;
      }
      _score = (_score - 1).clamp(0, _score);
    }
    notifyListeners();
  }

  void _wordCompleted() {
    _wordsCompleted++;
    _score += 10;
    _currentLetterIndex = 0;
    _failedAttempts = 0;
    _showingHint = false;
    _lastDetectedLetter = null;
    _recognitionMethod = '';
    _description = '';
    _status = 'NO HAND';
    _lastConfidence = 0.0;

    if (_comboCount % 5 == 0 && _comboCount > 0) {
      _score += 3;
    }

    if (_currentWordIndex + 1 < _words.length) {
      _currentWordIndex++;
    } else {
      _gameOver = true;
    }
    notifyListeners();
  }

  void _startCooldown() {
    _onCooldown = true;
    notifyListeners();
    Future.delayed(QuizService.letterCooldown, () {
      _onCooldown = false;
      notifyListeners();
    });
  }

  void updateDetectionStatus({String method = '', String description = '', String status = 'NO HAND'}) {
    _recognitionMethod = method;
    _description = description;
    _status = status;
    notifyListeners();
  }

  void skipLetter() {
    if (_currentLetterIndex + 1 < currentWord.length) {
      _currentLetterIndex++;
    } else {
      _wordCompleted();
    }
    _failedAttempts = 0;
    _showingHint = false;
    notifyListeners();
  }

  void tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _gameOver = true;
      notifyListeners();
    }
  }

  void endGame() {
    _gameOver = true;
    notifyListeners();
  }

  String getHint() {
    return service.getHint(currentTargetLetter);
  }

  int calculateFinalScore() {
    return service.calculateScore(
      wordsCompleted: _wordsCompleted,
      totalAttempts: _totalAttempts,
      correctAttempts: _correctAttempts,
      remainingSeconds: _remainingSeconds,
      comboCount: _comboCount,
    );
  }
}
