import 'package:flutter_test/flutter_test.dart';
import 'package:hisyarat/services/camera/prediction_filter.dart';

PredictionCandidate candidate(
  String label,
  double confidence,
  double margin,
  DateTime timestamp,
) {
  return PredictionCandidate(
    label: label,
    confidence: confidence,
    margin: margin,
    timestamp: timestamp,
  );
}

void main() {
  group('PredictionFilter', () {
    test('rejects low confidence and ambiguous predictions', () {
      final filter = PredictionFilter();
      final now = DateTime.now();

      expect(filter.accepts(candidate('A', 0.69, 0.40, now)), isFalse);
      expect(filter.accepts(candidate('A', 0.90, 0.14, now)), isFalse);
      expect(filter.accepts(candidate('A', 0.90, 0.30, now)), isTrue);
    });

    test('requires three matching accepted frames', () {
      final filter = PredictionFilter();
      final now = DateTime.now();

      expect(filter.add(candidate('B', 0.90, 0.30, now)), isNull);
      expect(
        filter.add(
          candidate(
            'B',
            0.91,
            0.31,
            now.add(const Duration(milliseconds: 100)),
          ),
        ),
        isNull,
      );
      expect(
        filter.add(
          candidate(
            'B',
            0.92,
            0.32,
            now.add(const Duration(milliseconds: 200)),
          ),
        ),
        'B',
      );
    });

    test('resets after rejected frame or long gap', () {
      final filter = PredictionFilter();
      final now = DateTime.now();

      for (var i = 0; i < 3; i++) {
        filter.add(
          candidate('C', 0.90, 0.30, now.add(Duration(milliseconds: i * 100))),
        );
      }
      expect(
        filter.add(
          candidate(
            'C',
            0.50,
            0.30,
            now.add(const Duration(milliseconds: 400)),
          ),
        ),
        isNull,
      );
      expect(
        filter.add(
          candidate('C', 0.90, 0.30, now.add(const Duration(seconds: 5))),
        ),
        isNull,
      );
    });
  });
}
