import 'dart:math';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image/image.dart' as img;
import 'bisindo_alphabet_data.dart';
import 'hand_crop_region.dart';
import 'tflite_classifier.dart';
import 'prediction_filter.dart';
import '../../core/constants.dart';

/// Result dari gesture recognition
class GestureResult {
  final String? detectedLetter;
  final double confidence;
  final String description;
  final String instruction;
  final bool handsDetected;
  final DateTime timestamp;
  final String recognitionMethod; // 'ai' atau 'rule-based'
  final Uint8List? snapshotJpeg;
  final Map<String, double> topPredictions;
  final String modelName;
  final String modelVersion;

  const GestureResult({
    this.detectedLetter,
    this.confidence = 0.0,
    this.description = '',
    this.instruction = '',
    this.handsDetected = false,
    required this.timestamp,
    this.recognitionMethod = '',
    this.snapshotJpeg,
    this.topPredictions = const {},
    this.modelName = '',
    this.modelVersion = '',
  });

  factory GestureResult.empty() => GestureResult(timestamp: DateTime.now());

  factory GestureResult.detected({
    required String letter,
    required double confidence,
    required String description,
    required String instruction,
    String method = 'rule-based',
    Uint8List? snapshotJpeg,
    Map<String, double> topPredictions = const {},
    String modelName = '',
    String modelVersion = '',
  }) => GestureResult(
    detectedLetter: letter,
    confidence: confidence,
    description: description,
    instruction: instruction,
    handsDetected: true,
    timestamp: DateTime.now(),
    recognitionMethod: method,
    snapshotJpeg: snapshotJpeg,
    topPredictions: topPredictions,
    modelName: modelName,
    modelVersion: modelVersion,
  );

  factory GestureResult.handsOnly() =>
      GestureResult(handsDetected: true, timestamp: DateTime.now());
}

/// Mode pengenalan gestur
enum RecognitionMode {
  /// Gunakan model AI (TFLite) sebagai primary
  aiPrimary,

  /// Gunakan rule-based sebagai primary
  ruleBased,

  /// Hybrid: AI dulu, fallback ke rule-based jika confidence rendah
  hybrid,
}

/// Service untuk mengenali gestur BISINDO dari kamera
/// Mendukung 3 mode: AI (TFLite), Rule-based, dan Hybrid
/// Singleton — reuse instance antar halaman untuk hindari reload model.
class GestureRecognizer {
  static GestureRecognizer? _instance;

  /// Get or create the shared instance. AI model is loaded once across pages.
  static Future<GestureRecognizer> getInstance() async {
    if (_instance == null) {
      _instance = GestureRecognizer();
      await _instance!.initializeAI();
    }
    return _instance!;
  }

  /// Dispose the shared instance (call only when app fully exits).
  static void disposeInstance() {
    _instance?.dispose();
    _instance = null;
  }

  PoseDetector? _poseDetector;
  final TFLiteClassifier _classifier;
  bool _isProcessing = false;

  // Recognition mode
  RecognitionMode _mode = RecognitionMode.aiPrimary;
  RecognitionMode get mode => _mode;

  final PredictionFilter _predictionFilter = PredictionFilter(
    minimumConfidence: AppConstants.aiPredictionConfidence,
    minimumMargin: AppConstants.aiPredictionMargin,
    windowSize: AppConstants.aiPredictionWindowSize,
    requiredMatches: AppConstants.aiPredictionRequiredMatches,
  );
  final List<String> _ruleRecentResults = [];
  static const int _ruleStabilizationWindow = 5;

  // Throttle
  DateTime _lastProcessTime = DateTime.now();
  static const Duration _processInterval = Duration(milliseconds: 200);

  // Stats
  int _aiDetections = 0;
  int _ruleDetections = 0;
  int get aiDetections => _aiDetections;
  int get ruleDetections => _ruleDetections;

  GestureRecognizer() : _classifier = TFLiteClassifier.instance;

  /// Initialize AI model (call this at app startup)
  Future<bool> initializeAI() async {
    final success = await _classifier.initialize();
    if (success) {
      _mode = RecognitionMode.aiPrimary;
      debugPrint('[GestureRecognizer] AI model loaded - AI-only mode active');
    } else {
      _mode = RecognitionMode.hybrid;
      debugPrint('[GestureRecognizer] AI model not available - falling back to hybrid mode');
    }
    return success;
  }

  /// Override prediction filter parameters (e.g. for quiz mode)
  void setPredictionFilter({
    double? minimumConfidence,
    double? minimumMargin,
    int? windowSize,
    int? requiredMatches,
  }) {
    _predictionFilter.setParameters(
      minimumConfidence: minimumConfidence ?? _predictionFilter.minimumConfidence,
      minimumMargin: minimumMargin ?? _predictionFilter.minimumMargin,
      windowSize: windowSize ?? _predictionFilter.windowSize,
      requiredMatches: requiredMatches ?? _predictionFilter.requiredMatches,
    );
    debugPrint('[GestureRecognizer] Prediction filter updated: '
        'conf=${_predictionFilter.minimumConfidence} '
        'margin=${_predictionFilter.minimumMargin} '
        'window=${_predictionFilter.windowSize} '
        'matches=${_predictionFilter.requiredMatches}');
  }

  /// Set recognition mode
  void setMode(RecognitionMode mode) {
    if (mode == RecognitionMode.aiPrimary && !_classifier.isInitialized) {
      debugPrint('[GestureRecognizer] Cannot set AI mode - model not loaded');
      return;
    }
    _mode = mode;
    debugPrint('[GestureRecognizer] Mode changed to: ${mode.name}');
  }

  /// Process a camera frame and return gesture result
  Future<GestureResult> processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    final now = DateTime.now();
    if (now.difference(_lastProcessTime) < _processInterval) {
      return GestureResult.empty();
    }
    if (_isProcessing) return GestureResult.empty();

    _isProcessing = true;
    _lastProcessTime = now;

    try {
      // ===== AI-BASED DETECTION =====
      if (_mode == RecognitionMode.aiPrimary ||
          _mode == RecognitionMode.hybrid) {
        // Coba dual-hand dulu (untuk huruf 2 tangan), fallback ke single-hand
        var handRegion = await _detectBothHandsRegion(image, camera);
        handRegion ??= await _detectHandRegion(image, camera);
        if (handRegion == null) {
          _predictionFilter.reset();
          if (_mode == RecognitionMode.aiPrimary) {
            _isProcessing = false;
            return GestureResult.handsOnly();
          }
        }

        final aiResult = handRegion == null
            ? null
            : await _classifyWithAI(image, camera, handRegion);

        if (aiResult != null) {
          debugPrint(
            '[AI] label=${aiResult.label} '
            'confidence=${aiResult.confidence.toStringAsFixed(3)} '
            'margin=${aiResult.margin.toStringAsFixed(3)}',
          );
          final sortedProbs = aiResult.allProbabilities.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final secondLabel = sortedProbs.length > 1 ? sortedProbs[1].key : '';
          final candidate = PredictionCandidate(
            label: aiResult.label,
            confidence: aiResult.confidence,
            margin: aiResult.margin,
            secondLabel: secondLabel,
            timestamp: aiResult.timestamp,
          );
          final filterAccepts = _predictionFilter.accepts(candidate);
          debugPrint(
            '[FILTER] accepted=$filterAccepts '
            'label=${aiResult.label} '
            'confidence=${aiResult.confidence.toStringAsFixed(3)} '
            'margin=${aiResult.margin.toStringAsFixed(3)}',
          );
          if (filterAccepts) {
            _aiDetections++;
            final stableLetter = _predictionFilter.add(candidate);

            if (stableLetter != null) {
              final gesture = BisindoAlphabetData.getByLetter(stableLetter);
              _isProcessing = false;
              return GestureResult.detected(
                letter: stableLetter,
                confidence: aiResult.confidence,
                description:
                    gesture?.description ?? 'Isyarat BISINDO: $stableLetter',
                instruction:
                    gesture?.instruction ?? 'Lakukan isyarat $stableLetter',
                method: 'ai',
                snapshotJpeg: _encodeSnapshot(aiResult),
                topPredictions: aiResult.allProbabilities,
                modelName: _classifier.profile.fileName,
                modelVersion: _classifier.profile.version,
              );
            }

            _isProcessing = false;
            return GestureResult.handsOnly();
          }

          // Frame ditolak: jangan reset buffer, tetap biarkan history
          // agar frame baik sebelumnya tidak hilang percuma.
          if (_mode == RecognitionMode.aiPrimary) {
            _isProcessing = false;
            return GestureResult.handsOnly();
          }
          // If hybrid and AI confidence is low, fall through to rule-based
        }
      }

      // Rule-based mode is retained for diagnostics only. The production
      // Mendeley model uses AI-only mode because the old rules describe a
      // different alphabet convention.
      if (_mode == RecognitionMode.ruleBased ||
          _mode == RecognitionMode.hybrid) {
        final result = await _classifyWithRules(image, camera);
        _isProcessing = false;
        return result;
      }

      _isProcessing = false;
      return GestureResult.empty();
    } catch (e) {
      debugPrint('[GestureRecognizer] Error processing frame: $e');
      _isProcessing = false;
      return GestureResult.empty();
    }
  }

  /// Classify using AI model (TFLite)
  Future<ClassificationResult?> _classifyWithAI(
    CameraImage image,
    CameraDescription camera,
    HandCropRegion handRegion,
  ) async {
    if (!_classifier.isInitialized) return null;

    try {
      final result = await _classifier.classifyFrame(image, camera, handRegion);
      if (result.isValid) {
        debugPrint(
          '[AI] Detected: ${result.label} (${(result.confidence * 100).toStringAsFixed(1)}%)',
        );
        return result;
      }
    } catch (e) {
      debugPrint('[AI] Classification error: $e');
    }
    return null;
  }

  Future<HandCropRegion?> _detectHandRegion(
    CameraImage image,
    CameraDescription camera,
  ) async {
    final inputImage = _convertCameraImage(image, camera);
    if (inputImage == null) return null;

    _poseDetector ??= PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
    final poses = await _poseDetector!.processImage(inputImage);
    if (poses.isEmpty) {
      debugPrint('[HAND] No poses detected');
      return null;
    }

    HandCropRegion? best;
    for (final pose in poses) {
      for (final side in _HandSide.values) {
        final region = _buildHandRegion(pose, side, image.width, image.height);
        if (region == null) continue;
        if (best == null || region.score > best.score) {
          best = region;
        }
      }
    }
    if (best == null) {
      debugPrint('[HAND] Found poses but no valid hand regions');
    }
    return best;
  }

  HandCropRegion? _buildHandRegion(
    Pose pose,
    _HandSide side,
    int imageWidth,
    int imageHeight,
  ) {
    PoseLandmark? landmark(PoseLandmarkType type) => pose.landmarks[type];

    final wrist = landmark(
      side == _HandSide.left
          ? PoseLandmarkType.leftWrist
          : PoseLandmarkType.rightWrist,
    );
    if (wrist == null || wrist.likelihood < 0.25) return null;

    final index = landmark(
      side == _HandSide.left
          ? PoseLandmarkType.leftIndex
          : PoseLandmarkType.rightIndex,
    );
    final thumb = landmark(
      side == _HandSide.left
          ? PoseLandmarkType.leftThumb
          : PoseLandmarkType.rightThumb,
    );
    final pinky = landmark(
      side == _HandSide.left
          ? PoseLandmarkType.leftPinky
          : PoseLandmarkType.rightPinky,
    );
    final leftShoulder = landmark(PoseLandmarkType.leftShoulder);
    final rightShoulder = landmark(PoseLandmarkType.rightShoulder);

    final shoulderWidth =
        leftShoulder != null && rightShoulder != null && imageWidth > 0
        ? (leftShoulder.x - rightShoulder.x).abs() / imageWidth
        : 0.0;
    final minimumSize = shoulderWidth > 0
        ? (shoulderWidth * 0.58).clamp(0.26, 0.46).toDouble()
        : 0.30;

    final points = <({double x, double y, double likelihood})>[
      _normalizedLandmark(wrist, imageWidth, imageHeight),
      if (index != null) _normalizedLandmark(index, imageWidth, imageHeight),
      if (thumb != null) _normalizedLandmark(thumb, imageWidth, imageHeight),
      if (pinky != null) _normalizedLandmark(pinky, imageWidth, imageHeight),
    ];

    return HandCropRegion.fromNormalizedPoints(
      points,
      minimumSize: minimumSize,
    );
  }

  /// Crop region yang mencakup KEDUA tangan sekaligus (untuk huruf 2 tangan)
  Future<HandCropRegion?> _detectBothHandsRegion(
    CameraImage image,
    CameraDescription camera,
  ) async {
    final inputImage = _convertCameraImage(image, camera);
    if (inputImage == null) return null;

    _poseDetector ??= PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      ),
    );
    final poses = await _poseDetector!.processImage(inputImage);
    if (poses.isEmpty) return null;

    for (final pose in poses) {
      final points = <({double x, double y, double likelihood})>[];

      final handLandmarkTypes = [
        PoseLandmarkType.leftWrist,    PoseLandmarkType.rightWrist,
        PoseLandmarkType.leftIndex,    PoseLandmarkType.rightIndex,
        PoseLandmarkType.leftPinky,    PoseLandmarkType.rightPinky,
        PoseLandmarkType.leftThumb,    PoseLandmarkType.rightThumb,
      ];

      for (final type in handLandmarkTypes) {
        final lm = pose.landmarks[type];
        if (lm != null && lm.likelihood >= 0.25) {
          points.add(_normalizedLandmark(lm, image.width, image.height));
        }
      }

      if (points.length < 4) continue;

      final leftPoints = points.where((p) => p.x < 0.5).length;
      final rightPoints = points.length - leftPoints;
      if (leftPoints == 0 || rightPoints == 0) return null;

      return HandCropRegion.fromNormalizedPoints(
        points,
        paddingScale: 2.2,
      );
    }
    return null;
  }

  ({double x, double y, double likelihood}) _normalizedLandmark(
    PoseLandmark landmark,
    int imageWidth,
    int imageHeight,
  ) {
    return (
      x: (landmark.x / imageWidth).clamp(0.0, 1.0).toDouble(),
      y: (landmark.y / imageHeight).clamp(0.0, 1.0).toDouble(),
      likelihood: landmark.likelihood,
    );
  }

  Uint8List? _encodeSnapshot(ClassificationResult result) {
    final bytes = result.rgbBytes;
    if (bytes == null || result.imageWidth <= 0 || result.imageHeight <= 0) {
      return null;
    }
    final src = img.Image.fromBytes(
      width: result.imageWidth,
      height: result.imageHeight,
      bytes: bytes.buffer,
      order: img.ChannelOrder.rgb,
    );
    final maxDim = 320;
    final image = result.imageWidth > maxDim || result.imageHeight > maxDim
        ? img.copyResize(src,
            width: maxDim,
            height: (src.height * maxDim / src.width).round())
        : src;
    return Uint8List.fromList(img.encodeJpg(image, quality: 50));
  }

  /// Classify using rule-based pose detection (original method)
  Future<GestureResult> _classifyWithRules(
    CameraImage image,
    CameraDescription camera,
  ) async {
    try {
      final inputImage = _convertCameraImage(image, camera);
      if (inputImage == null) return GestureResult.empty();

      _poseDetector ??= PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isEmpty) {
        _predictionFilter.reset();
        return GestureResult.empty();
      }

      final pose = poses.first;
      final hasHands = _hasHandLandmarks(pose);

      if (!hasHands) return GestureResult.empty();

      final classification = _classifyGesture(pose);

      if (classification != null) {
        _ruleDetections++;
        _addToBuffer(classification.letter);

        final stableLetter = _getStableResult();
        if (stableLetter != null) {
          final gesture = BisindoAlphabetData.getByLetter(stableLetter);
          if (gesture != null) {
            return GestureResult.detected(
              letter: stableLetter,
              confidence: classification.confidence,
              description: gesture.description,
              instruction: gesture.instruction,
              method: 'rule-based',
            );
          }
        }
        return GestureResult.handsOnly();
      }

      return GestureResult.handsOnly();
    } catch (e) {
      debugPrint('[Rules] Error: $e');
      return GestureResult.empty();
    }
  }

  /// Add result to stabilization buffer
  void _addToBuffer(String letter) {
    _ruleRecentResults.add(letter);
    if (_ruleRecentResults.length > _ruleStabilizationWindow) {
      _ruleRecentResults.removeAt(0);
    }
  }

  /// Convert CameraImage to InputImage
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
      if (rotation == null) return null;

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Check if pose has hand landmarks
  bool _hasHandLandmarks(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    return (leftWrist != null && leftWrist.likelihood > 0.5) ||
        (rightWrist != null && rightWrist.likelihood > 0.5);
  }

  /// Classify gesture based on pose landmarks (rule-based)
  _ClassResult? _classifyGesture(Pose pose) {
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    final le = pose.landmarks[PoseLandmarkType.leftElbow];
    final re = pose.landmarks[PoseLandmarkType.rightElbow];
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final li = pose.landmarks[PoseLandmarkType.leftIndex];
    final ri = pose.landmarks[PoseLandmarkType.rightIndex];
    final lt = pose.landmarks[PoseLandmarkType.leftThumb];
    final rt = pose.landmarks[PoseLandmarkType.rightThumb];
    final lp = pose.landmarks[PoseLandmarkType.leftPinky];
    final rp = pose.landmarks[PoseLandmarkType.rightPinky];

    if (lw == null || rw == null || le == null || re == null) return null;

    // Shoulder width as reference scale
    final sw = (ls != null && rs != null) ? (ls.x - rs.x).abs() : 200.0;

    // Wrist distance
    final wristDist = _dist(lw, rw);
    final handsClose = wristDist < sw * 0.5;
    final handsTouching = wristDist < sw * 0.25;

    // Hand heights
    final rHandHigh = rs != null && rw.y < rs.y;
    final lHandHigh = ls != null && lw.y < ls.y;
    final bothUp = rHandHigh && lHandHigh;

    // Finger spread
    final lSpread = (li != null && lp != null) ? _dist(li, lp) : 0.0;
    final rSpread = (ri != null && rp != null) ? _dist(ri, rp) : 0.0;

    // Thumb up
    final lThumbUp = lt != null && lt.y < lw.y - 30;
    final rThumbUp = rt != null && rt.y < rw.y - 30;

    // Index up
    final rIndexUp = ri != null && ri.y < rw.y - 40;

    // Pinky up
    final rPinkyUp = rp != null && rp.y < rw.y - 40;

    // ===== CLASSIFICATION RULES =====

    // Y: Thumb + pinky out (shaka)
    if (rThumbUp && !rIndexUp && rPinkyUp && rSpread > sw * 0.15) {
      return _ClassResult('Y', 0.75);
    }

    // I: Only pinky up
    if (!rThumbUp && !rIndexUp && rPinkyUp && rSpread < sw * 0.15) {
      return _ClassResult('I', 0.70);
    }

    // L: Thumb + index forming L
    if (rThumbUp &&
        rIndexUp &&
        rSpread < sw * 0.2 &&
        (ri.x - rt.x).abs() > sw * 0.15) {
      return _ClassResult('L', 0.72);
    }

    // D: Only index up
    if (!rThumbUp && rIndexUp && rSpread < sw * 0.12) {
      return _ClassResult('D', 0.72);
    }

    // V: Two fingers up, spread
    if (!rThumbUp && rIndexUp && rSpread > sw * 0.1 && rSpread < sw * 0.25) {
      return _ClassResult('V', 0.68);
    }

    // W: Three fingers up
    if (!rThumbUp && rHandHigh && rSpread > sw * 0.2 && rSpread < sw * 0.35) {
      return _ClassResult('W', 0.63);
    }

    // B: Four fingers up, no thumb
    if (!rThumbUp && rHandHigh && rSpread > sw * 0.3) {
      return _ClassResult('B', 0.65);
    }

    // F: OK sign - thumb+index circle, others up
    if (rThumbUp && rIndexUp && rSpread > sw * 0.25) {
      return _ClassResult('F', 0.62);
    }

    // K: Thumb + two fingers
    if (rThumbUp && rIndexUp && rSpread > sw * 0.12 && rSpread < sw * 0.22) {
      return _ClassResult('K', 0.62);
    }

    // A: Fist with thumb to side
    if (handsClose && lSpread < sw * 0.15 && rSpread < sw * 0.15 && lThumbUp) {
      return _ClassResult('A', 0.70);
    }

    // O: Hands forming circle
    if (handsTouching && lSpread < sw * 0.2 && rSpread < sw * 0.2) {
      return _ClassResult('O', 0.62);
    }

    // C: Curved hand
    if (rHandHigh && rSpread > sw * 0.12 && rSpread < sw * 0.22 && !rIndexUp) {
      return _ClassResult('C', 0.58);
    }

    // S/E: Fist - both closed
    if (handsClose &&
        lSpread < sw * 0.1 &&
        rSpread < sw * 0.1 &&
        !lThumbUp &&
        !rThumbUp) {
      return _ClassResult('S', 0.62);
    }

    // G: Pointing sideways
    if (ri != null &&
        (ri.x - rw.x).abs() > sw * 0.3 &&
        (ri.y - rw.y).abs() < sw * 0.15) {
      return _ClassResult('G', 0.60);
    }

    // R: Crossed fingers (index up, tight spread)
    if (rIndexUp && rSpread < sw * 0.08) {
      return _ClassResult('R', 0.58);
    }

    // M/N: Fist variations, both hands up close
    if (bothUp && handsClose && lSpread < sw * 0.15 && rSpread < sw * 0.15) {
      return _ClassResult('M', 0.55);
    }

    // H/U: Two fingers up, close together
    if (!rThumbUp && rIndexUp && rSpread > sw * 0.05 && rSpread < sw * 0.12) {
      return _ClassResult('U', 0.60);
    }

    return null;
  }

  /// Get stable result from buffer
  String? _getStableResult() {
    if (_ruleRecentResults.length < 3) return null;

    final counts = <String, int>{};
    for (final r in _ruleRecentResults) {
      counts[r] = (counts[r] ?? 0) + 1;
    }

    String? best;
    int bestCount = 0;
    counts.forEach((letter, count) {
      if (count > bestCount) {
        bestCount = count;
        best = letter;
      }
    });

    if (bestCount >= (_ruleStabilizationWindow * 0.6).ceil()) return best;
    return null;
  }

  double _dist(PoseLandmark a, PoseLandmark b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  void reset() {
    _predictionFilter.reset();
    _ruleRecentResults.clear();
    _isProcessing = false;
    _aiDetections = 0;
    _ruleDetections = 0;
  }

  Future<void> dispose() async {
    await _poseDetector?.close();
    _predictionFilter.reset();
    _ruleRecentResults.clear();
    // Note: Don't dispose classifier here as it's a singleton
    // It will be disposed when the app closes
  }
}

class _ClassResult {
  final String letter;
  final double confidence;
  const _ClassResult(this.letter, this.confidence);
}

enum _HandSide { left, right }
