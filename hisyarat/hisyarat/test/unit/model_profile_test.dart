import 'package:flutter_test/flutter_test.dart';
import 'package:hisyarat/services/camera/model_profile.dart';

void main() {
  test('public v2 model is the default profile', () {
    expect(ModelProfile.selected.id, 'public-v2');
    expect(ModelProfile.selected.fileName, 'bisindo_curriculum_v2.tflite');
    expect(ModelProfile.selected.outputIsProbability, isTrue);
    expect(ModelProfile.selected.imageNetNormalization, isFalse);
  });

  test('public v2 falls back through the older packaged models', () {
    expect(
      ModelProfile.fallbackFor(ModelProfile.publicV2),
      ModelProfile.generalization,
    );
    expect(
      ModelProfile.fallbackFor(ModelProfile.generalization),
      ModelProfile.legacy,
    );
    expect(ModelProfile.fallbackFor(ModelProfile.legacy), isNull);
  });

  test('legacy profile retains old preprocessing contract', () {
    expect(ModelProfile.legacy.outputIsProbability, isFalse);
    expect(ModelProfile.legacy.imageNetNormalization, isTrue);
  });
}
