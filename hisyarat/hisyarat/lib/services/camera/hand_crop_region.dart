import 'package:flutter/foundation.dart';

class HandCropRegion {
  final double centerX;
  final double centerY;
  final double size;
  final double score;

  const HandCropRegion({
    required this.centerX,
    required this.centerY,
    required this.size,
    required this.score,
  });

  double get left => centerX - size / 2;
  double get top => centerY - size / 2;
  double get right => centerX + size / 2;
  double get bottom => centerY + size / 2;

  bool get isReasonableAspect {
    return centerX >= 0.05 && centerX <= 0.95 &&
        centerY >= 0.05 && centerY <= 0.95;
  }

  bool get isUsable {
    return score >= 0.25 &&
        size >= 0.10 &&
        size <= 0.85 &&
        isReasonableAspect &&
        left >= -0.15 &&
        top >= -0.15 &&
        right <= 1.15 &&
        bottom <= 1.15;
  }

  HandCropRegion clampInsideFrame() {
    final half = size / 2;
    return HandCropRegion(
      centerX: centerX.clamp(half, 1 - half).toDouble(),
      centerY: centerY.clamp(half, 1 - half).toDouble(),
      size: size,
      score: score,
    );
  }

  static HandCropRegion? fromNormalizedPoints(
    List<({double x, double y, double likelihood})> points, {
    double minimumSize = 0.18,
    double paddingScale = 1.8,
  }) {
    final usable = points
        .where(
          (point) =>
              point.likelihood >= 0.25 && point.x.isFinite && point.y.isFinite,
        )
        .toList();
    if (usable.length < 2) {
      debugPrint('[HAND] Not enough usable points: ${usable.length}');
      return null;
    }

    var minX = usable.first.x;
    var maxX = usable.first.x;
    var minY = usable.first.y;
    var maxY = usable.first.y;
    var score = 0.0;
    for (final point in usable) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
      score += point.likelihood;
    }
    score /= usable.length;

    final width = maxX - minX;
    final height = maxY - minY;
    final handSize = width > height ? width : height;

    // Adaptive padding: tangan kecil (jauh) → padding besar, tangan besar (dekat) → padding kecil
    const referenceSize = 0.25;
    final sizeFactor = (referenceSize / handSize).clamp(0.8, 1.6);
    final adaptivePadding = paddingScale * sizeFactor;

    final paddedSize = handSize * adaptivePadding;
    final size = paddedSize.clamp(minimumSize, 0.78).toDouble();

    final region = HandCropRegion(
      centerX: ((minX + maxX) / 2).clamp(0.0, 1.0).toDouble(),
      centerY: ((minY + maxY) / 2).clamp(0.0, 1.0).toDouble(),
      size: size,
      score: score,
    );
    if (!region.isUsable) {
      debugPrint('[HAND] Region not usable: score=${region.score.toStringAsFixed(2)} size=${region.size.toStringAsFixed(2)}');
      return null;
    }
    debugPrint('[HAND] Region OK: center=(${region.centerX.toStringAsFixed(2)}, ${region.centerY.toStringAsFixed(2)}) size=${region.size.toStringAsFixed(2)}');
    return region.clampInsideFrame();
  }
}
