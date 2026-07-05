class PredictionCandidate {
  final String label;
  final double confidence;
  final double margin;
  final String secondLabel;
  final DateTime timestamp;

  const PredictionCandidate({
    required this.label,
    required this.confidence,
    required this.margin,
    required this.timestamp,
    this.secondLabel = '',
  });
}

class PredictionFilter {
  double minimumConfidence;
  double minimumMargin;
  int windowSize;
  int requiredMatches;
  final Duration maximumGap;

  final List<PredictionCandidate> _recent = [];
  bool _hasEmitted = false;
  String? _emittedLabel;

  bool get hasEmitted => _hasEmitted;
  String? get emittedLabel => _emittedLabel;

  // Pasangan huruf yang sering salah prediksi satu sama lain
  static const Map<String, List<String>> _confusablePairs = {
    'J': ['I'],
    'I': ['J'],
    'M': ['J', 'N'],
    'N': ['I', 'M'],
    'P': ['D', 'F'],
    'D': ['P'],
    'F': ['P'],
  };

  PredictionFilter({
    this.minimumConfidence = 0.70,
    this.minimumMargin = 0.15,
    this.windowSize = 5,
    this.requiredMatches = 3,
    this.maximumGap = const Duration(seconds: 2),
  });

  void setParameters({
    double? minimumConfidence,
    double? minimumMargin,
    int? windowSize,
    int? requiredMatches,
  }) {
    if (minimumConfidence != null) this.minimumConfidence = minimumConfidence;
    if (minimumMargin != null) this.minimumMargin = minimumMargin;
    if (windowSize != null) this.windowSize = windowSize;
    if (requiredMatches != null) this.requiredMatches = requiredMatches;
  }

  /// Jika top-1 dan top-2 adalah pasangan confusable, naikkan requiredMatches
  /// untuk mengurangi false positive.
  int _effectiveRequiredMatches(String top1, String top2) {
    final confusables = _confusablePairs[top1];
    if (confusables != null && confusables.contains(top2)) {
      return (requiredMatches + 1).clamp(1, windowSize);
    }
    return requiredMatches;
  }

  bool accepts(PredictionCandidate candidate) {
    return candidate.confidence >= minimumConfidence &&
        candidate.margin >= minimumMargin;
  }

  String? add(PredictionCandidate candidate) {
    if (_hasEmitted) {
      // If enough time passed since last valid candidate, auto-reset
      // so user can make the next gesture without waiting for hand to disappear
      if (_recent.isNotEmpty &&
          candidate.timestamp.difference(_recent.last.timestamp) > maximumGap) {
        reset();
      } else {
        return null;
      }
    }

    if (_recent.isNotEmpty &&
        candidate.timestamp.difference(_recent.last.timestamp) > maximumGap) {
      reset();
      return null;
    }

    if (!accepts(candidate)) {
      return null;
    }

    _recent.add(candidate);
    if (_recent.length > windowSize) {
      _recent.removeAt(0);
    }

    final counts = <String, int>{};
    final confidenceSums = <String, double>{};
    final confidenceCounts = <String, int>{};
    for (final result in _recent) {
      counts[result.label] = (counts[result.label] ?? 0) + 1;
      confidenceSums[result.label] =
          (confidenceSums[result.label] ?? 0) + result.confidence;
      confidenceCounts[result.label] =
          (confidenceCounts[result.label] ?? 0) + 1;
    }

    String? best;
    var bestCount = 0;
    var bestAvgConfidence = 0.0;
    for (final entry in counts.entries) {
      final avgConf = confidenceCounts[entry.key]! > 0
          ? confidenceSums[entry.key]! / confidenceCounts[entry.key]!
          : 0.0;
      if (entry.value > bestCount ||
          (entry.value == bestCount && avgConf > bestAvgConfidence)) {
        best = entry.key;
        bestCount = entry.value;
        bestAvgConfidence = avgConf;
      }
    }

    if (best != null) {
      final avgConf = confidenceSums[best]! / confidenceCounts[best]!;
      final effective = _effectiveRequiredMatches(best, candidate.secondLabel);
      if (bestCount >= effective && avgConf >= minimumConfidence) {
        _hasEmitted = true;
        _emittedLabel = best;
        return best;
      }
    }
    return null;
  }

  void reset() {
    _recent.clear();
    _hasEmitted = false;
    _emittedLabel = null;
  }
}
