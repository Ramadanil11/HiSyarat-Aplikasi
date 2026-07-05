import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants.dart';
import 'hand_crop_region.dart';
import 'model_profile.dart';

class ClassificationResult {
  final String label;
  final double confidence;
  final double margin;
  final Map<String, double> allProbabilities;
  final Uint8List? rgbBytes;
  final int imageWidth;
  final int imageHeight;
  final DateTime timestamp;

  const ClassificationResult({
    required this.label,
    required this.confidence,
    required this.margin,
    required this.allProbabilities,
    this.rgbBytes,
    this.imageWidth = 0,
    this.imageHeight = 0,
    required this.timestamp,
  });

  factory ClassificationResult.empty() => ClassificationResult(
    label: '',
    confidence: 0,
    margin: 0,
    allProbabilities: const {},
    timestamp: DateTime.now(),
  );

  bool get isValid => label.isNotEmpty && confidence > 0;
}

class TFLiteClassifier {
  static TFLiteClassifier? _instance;
  static TFLiteClassifier get instance => _instance ??= TFLiteClassifier._();
  TFLiteClassifier._();

  static const int _inputSize = 224;
  static const double _roiSize = .64;
  static const double _roiCenterY = .55;
  static const List<double> _mean = [.485, .456, .406];
  static const List<double> _std = [.229, .224, .225];

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  ModelProfile profile = ModelProfile.selected;

  bool get isInitialized => _isInitialized;
  List<String> get labels => List.unmodifiable(_labels);
  int get numClasses => _labels.length;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isLoading) return false;
    _isLoading = true;
    try {
      var nextProfile = profile;
      while (true) {
        try {
          final path = '${AppConstants.aiModelPath}${nextProfile.fileName}';
          final options = InterpreterOptions()..threads = 2;

          // Android: GPU delegate (XNNPack fallback)
          if (Platform.isAndroid) {
            try {
              options.addDelegate(GpuDelegateV2());
              debugPrint('[TFLite] GPU delegate enabled (Android)');
            } catch (e) {
              debugPrint('[TFLite] GPU unavailable, trying XNNPack: $e');
              try {
                options.addDelegate(XNNPackDelegate());
                debugPrint('[TFLite] XNNPack delegate enabled');
              } catch (e2) {
                debugPrint('[TFLite] XNNPack unavailable, using CPU: $e2');
              }
            }
          }

          // iOS: Metal GPU delegate, fallback CoreML
          if (Platform.isIOS) {
            try {
              options.addDelegate(GpuDelegate());
              debugPrint('[TFLite] Metal GPU delegate enabled (iOS)');
            } catch (e) {
              debugPrint('[TFLite] Metal unavailable, trying CoreML: $e');
              try {
                options.addDelegate(CoreMlDelegate());
                debugPrint('[TFLite] CoreML delegate enabled');
              } catch (e2) {
                debugPrint('[TFLite] CoreML unavailable, using CPU: $e2');
              }
            }
          }

          _interpreter = await Interpreter.fromAsset(path, options: options);
          profile = nextProfile;
          await _loadLabels();
          _validateModelContract();
          _isInitialized = true;
          debugPrint(
            '[TFLite] Active profile: ${profile.id} (${profile.version})',
          );
          debugPrint('[TFLite] Model loaded successfully (${_labels.length} labels)');
          return true;
        } catch (error) {
          _interpreter?.close();
          _interpreter = null;
          final fallback = ModelProfile.fallbackFor(nextProfile);
          if (fallback == null) return false;
          if (fallback.id == 'legacy') {
            debugPrint(
              '========================================\n'
              '[TFLite]  WARNING: ${nextProfile.id} gagal dimuat!\n'
              '         Error: $error\n'
              '         Akurasi model akan TURUN karena fallback ke legacy model.\n'
              '         Upgrade tflite_flutter atau re-export model.\n'
              '========================================',
            );
          } else {
            debugPrint('[TFLite] ${nextProfile.id} failed: $error');
          }
          nextProfile = fallback;
          profile = fallback;
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final source = await rootBundle.loadString(
        '${AppConstants.aiModelPath}labels.json',
      );
      final data = jsonDecode(source);
      _labels = List<String>.from(data is Map ? data['labels'] : data);
    } catch (_) {
      _labels = List.generate(26, (index) => String.fromCharCode(65 + index));
    }
  }

  void _validateModelContract() {
    final interpreter = _interpreter;
    if (interpreter == null) return;

    final inputShape = interpreter.getInputTensor(0).shape;
    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputClasses = outputShape.isNotEmpty ? outputShape.last : 0;

    if (inputShape.length != 4 ||
        inputShape[1] != _inputSize ||
        inputShape[2] != _inputSize ||
        inputShape[3] != 3) {
      throw StateError(
        'Unexpected input shape $inputShape; expected [1, $_inputSize, $_inputSize, 3]',
      );
    }
    if (outputClasses != _labels.length) {
      throw StateError(
        'Unexpected output classes $outputClasses; labels=${_labels.length}',
      );
    }
  }

  Future<ClassificationResult> classifyFrame(
    CameraImage image,
    CameraDescription camera,
    HandCropRegion? handRegion,
  ) async {
    if (!_isInitialized || _interpreter == null) {
      return ClassificationResult.empty();
    }
    try {
      final prepared = _prepareRoi(image, camera, handRegion);
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
      _interpreter!.run(prepared.input, output);
      final probabilities = profile.outputIsProbability
          ? output.first.map((value) => value.clamp(0.0, 1.0)).toList()
          : _softmax(output.first);
      final ranked = List<int>.generate(probabilities.length, (i) => i)
        ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));
      final best = ranked.first;
      final runnerUp = ranked.length > 1 ? probabilities[ranked[1]] : 0.0;
      final top3 = ranked.take(3).map((i) => '${_labels[i]}=${probabilities[i].toStringAsFixed(3)}').join(' ');
      debugPrint('[TFLite] TOP3: $top3');
      return ClassificationResult(
        label: _labels[best],
        confidence: probabilities[best],
        margin: probabilities[best] - runnerUp,
        allProbabilities: {
          for (var i = 0; i < probabilities.length; i++)
            _labels[i]: probabilities[i],
        },
        rgbBytes: prepared.rgb,
        imageWidth: _inputSize,
        imageHeight: _inputSize,
        timestamp: DateTime.now(),
      );
    } catch (error) {
      debugPrint('[TFLite] Classification failed: $error');
      return ClassificationResult.empty();
    }
  }

  _PreparedRoi _prepareRoi(
    CameraImage image,
    CameraDescription camera,
    HandCropRegion? handRegion,
  ) {
    final rgb = Uint8List(_inputSize * _inputSize * 3);
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(_inputSize, (_) => List.filled(3, 0.0)),
      ),
    );

    final isBgra = image.format.group == ImageFormatGroup.bgra8888;
    final frameWidth = image.width;
    final frameHeight = image.height;

    // Cache untuk BGRA: plane 0 bytes + bytesPerRow
    // Cache untuk NV21: plane Y + uvStart
    final bgraPlane = isBgra ? image.planes.first : null;
    final bgraBpr = isBgra ? bgraPlane!.bytesPerRow : 0;

    final yPlane = isBgra ? null : image.planes.first;
    final bytesPerRow = isBgra ? 0 : yPlane!.bytesPerRow;
    final uvStart = isBgra ? 0 : bytesPerRow * frameHeight;

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final rawPoint = handRegion == null
            ? _defaultRoiPoint(x, y, camera)
            : _handRegionPoint(x, y, handRegion);
        final rawX = (rawPoint.$1 * frameWidth).floor().clamp(
          0,
          frameWidth - 1,
        );
        final rawY = (rawPoint.$2 * frameHeight).floor().clamp(
          0,
          frameHeight - 1,
        );

        int r, g, b;

        if (isBgra) {
          // iOS: BGRA8888 — 4 bytes per pixel, interleaved, 1 plane
          final plane = bgraPlane!;
          final idx = rawY * bgraBpr + rawX * 4;
          if (idx + 3 < plane.bytes.length) {
            b = plane.bytes[idx];       // Blue
            g = plane.bytes[idx + 1];   // Green
            r = plane.bytes[idx + 2];   // Red
            // idx+3 = Alpha, ignore
          } else {
            r = 0; g = 0; b = 0;
          }
        } else {
          // Android: NV21
          final plane = yPlane!;

          // Y value (luma)
          final yIndex = rawY * bytesPerRow + rawX;
          final luma = yIndex < plane.bytes.length ? plane.bytes[yIndex] : 0;

          // UV value — NV21: V before U, subsampled 2×2
          final uvRow = rawY ~/ 2;
          final uvCol = rawX ~/ 2;
          int u = 128;
          int v = 128;
          final planeCount = image.planes.length;
          if (planeCount == 3) {
            // 3-plane NV21: plane[0]=Y, plane[1]=V(Cr), plane[2]=U(Cb)
            final vIndex = uvRow * (image.planes[1].bytesPerRow) + uvCol;
            final uIndex = uvRow * (image.planes[2].bytesPerRow) + uvCol;
            if (vIndex < image.planes[1].bytes.length) {
              v = image.planes[1].bytes[vIndex];
            }
            if (uIndex < image.planes[2].bytes.length) {
              u = image.planes[2].bytes[uIndex];
            }
          } else if (planeCount == 2) {
            // 2-plane NV21: plane[0]=Y, plane[1]=VU interleaved
            final plane1 = image.planes[1];
            final vuIndex = uvRow * plane1.bytesPerRow + uvCol * 2;
            if (vuIndex + 1 < plane1.bytes.length) {
              v = plane1.bytes[vuIndex];
              u = plane1.bytes[vuIndex + 1];
            }
          } else {
            // Single-plane NV21: Y data then interleaved VU
            final vuIndex = uvStart + uvRow * bytesPerRow + uvCol * 2;
            if (vuIndex + 1 < plane.bytes.length) {
              v = plane.bytes[vuIndex];
              u = plane.bytes[vuIndex + 1];
            }
          }

          // YUV → RGB (ITU-R BT.601)
          r = (luma + 1.370705 * (v - 128)).round().clamp(0, 255);
          g = (luma - 0.337633 * (u - 128) - 0.698001 * (v - 128))
              .round().clamp(0, 255);
          b = (luma + 1.732446 * (u - 128)).round().clamp(0, 255);
        }

        final rgbIndex = (y * _inputSize + x) * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;

        final values = [r.toDouble(), g.toDouble(), b.toDouble()];
        for (var channel = 0; channel < 3; channel++) {
          input[0][y][x][channel] = profile.imageNetNormalization
              ? (values[channel] / 255 - _mean[channel]) / _std[channel]
              : values[channel];
        }
      }
    }
    return _PreparedRoi(input, rgb);
  }

  (double, double) _defaultRoiPoint(int x, int y, CameraDescription camera) {
    var uprightX = .5 - _roiSize / 2 + ((x + .5) / _inputSize) * _roiSize;
    final uprightY =
        _roiCenterY - _roiSize / 2 + ((y + .5) / _inputSize) * _roiSize;
    if (camera.lensDirection == CameraLensDirection.front) {
      uprightX = 1 - uprightX;
    }
    return _toRaw(uprightX, uprightY, camera.sensorOrientation);
  }

  (double, double) _handRegionPoint(int x, int y, HandCropRegion region) {
    return (
      region.left + ((x + .5) / _inputSize) * region.size,
      region.top + ((y + .5) / _inputSize) * region.size,
    );
  }

  (double, double) _toRaw(double x, double y, int rotation) {
    switch (rotation % 360) {
      case 90:
        return (y, 1 - x);
      case 180:
        return (1 - x, 1 - y);
      case 270:
        return (1 - y, x);
      default:
        return (x, y);
    }
  }

  List<double> _softmax(List<double> logits) {
    final largest = logits.reduce(max);
    final exponents = logits.map((value) => exp(value - largest)).toList();
    final total = exponents.reduce((a, b) => a + b);
    return exponents.map((value) => value / total).toList();
  }

  List<MapEntry<String, double>> getTopK(Map<String, double> values, int k) {
    final sorted = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(k).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _instance = null;
  }
}

class _PreparedRoi {
  final List<List<List<List<double>>>> input;
  final Uint8List rgb;
  const _PreparedRoi(this.input, this.rgb);
}
