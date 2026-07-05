import 'package:flutter_test/flutter_test.dart';
import 'package:hisyarat/services/camera/hand_crop_region.dart';

void main() {
  group('HandCropRegion', () {
    test('builds a padded square crop from confident hand points', () {
      final region = HandCropRegion.fromNormalizedPoints([
        (x: 0.45, y: 0.45, likelihood: 0.90),
        (x: 0.52, y: 0.38, likelihood: 0.88),
        (x: 0.40, y: 0.42, likelihood: 0.86),
      ]);

      expect(region, isNotNull);
      expect(region!.isUsable, isTrue);
      expect(region.centerX, closeTo(0.46, 0.02));
      expect(region.centerY, closeTo(0.415, 0.02));
      expect(region.size, greaterThanOrEqualTo(0.22));
    });

    test('rejects weak or insufficient landmark groups', () {
      expect(
        HandCropRegion.fromNormalizedPoints([
          (x: 0.50, y: 0.50, likelihood: 0.90),
        ]),
        isNull,
      );
      expect(
        HandCropRegion.fromNormalizedPoints([
          (x: 0.50, y: 0.50, likelihood: 0.20),
          (x: 0.55, y: 0.45, likelihood: 0.25),
        ]),
        isNull,
      );
    });

    test('clamps a valid edge crop inside the frame', () {
      final region = HandCropRegion.fromNormalizedPoints([
        (x: 0.04, y: 0.50, likelihood: 0.90),
        (x: 0.12, y: 0.44, likelihood: 0.85),
        (x: 0.08, y: 0.56, likelihood: 0.86),
      ]);

      expect(region, isNotNull);
      expect(region!.left, greaterThanOrEqualTo(0));
      expect(region.right, lessThanOrEqualTo(1));
    });
  });
}
