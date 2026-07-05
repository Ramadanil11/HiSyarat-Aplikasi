class ModelProfile {
  final String id;
  final String fileName;
  final String version;
  final bool outputIsProbability;
  final bool imageNetNormalization;

  const ModelProfile({
    required this.id,
    required this.fileName,
    required this.version,
    required this.outputIsProbability,
    required this.imageNetNormalization,
  });

  static const publicV2 = ModelProfile(
    id: 'public-v2',
    fileName: 'bisindo_curriculum_v2.tflite',
    version: 'curriculum-cross-signer-v2',
    outputIsProbability: true,
    imageNetNormalization: true,
  );

  static const generalization = ModelProfile(
    id: 'generalization-v1',
    fileName: 'bisindo_generalization_v1.tflite',
    version: 'all-signers-efficientnet-v1',
    outputIsProbability: true,
    imageNetNormalization: true,
  );

  static const legacy = ModelProfile(
    id: 'legacy',
    fileName: 'bisindo_model.tflite',
    version: 'legacy-mobilenet-v2',
    outputIsProbability: false,
    imageNetNormalization: true,
  );

  static const selectedId = String.fromEnvironment(
    'HISYARAT_MODEL_PROFILE',
    defaultValue: 'public-v2',
  );

  static ModelProfile get selected {
    if (selectedId == legacy.id) return legacy;
    if (selectedId == generalization.id) return generalization;
    return publicV2;
  }

  static ModelProfile? fallbackFor(ModelProfile profile) {
    if (profile.id == publicV2.id) return generalization;
    if (profile.id == generalization.id) return legacy;
    return null;
  }
}
