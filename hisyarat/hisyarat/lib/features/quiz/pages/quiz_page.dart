import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/camera/gesture_recognizer.dart';
import '../providers/quiz_provider.dart';
import '../services/quiz_service.dart';
import '../widgets/progress_word_widget.dart';
import '../widgets/score_widget.dart';
import '../widgets/timer_widget.dart';
import 'quiz_result_page.dart';

class QuizPage extends StatefulWidget {
  final String category;
  final int timeLimitSeconds;

  const QuizPage({
    super.key,
    required this.category,
    required this.timeLimitSeconds,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final QuizProvider _provider;
  late final QuizService _quizService;

  CameraController? _cameraController;
  GestureRecognizer? _gestureRecognizer;
  bool _cameraReady = false;
  bool _cameraError = false;
  bool _cameraInitializing = false;
  bool _quizStarted = false;
  bool _isDetecting = false;
  bool _frameProcessing = false;
  bool _isFrontCamera = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService(category: widget.category);
    _provider = QuizProvider(service: _quizService, timeLimit: widget.timeLimitSeconds);
    _initQuiz();
    _initCamera();
  }

  Future<void> _initQuiz() async {
    await _quizService.loadWords();
    _provider.loadWords(_quizService.getWordsForCategory());
  }

  Future<void> _initCamera() async {
    if (_cameraInitializing) return;
    _cameraInitializing = true;

    try {
      if (mounted) setState(() => _cameraError = false);

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() {
          _cameraInitializing = false;
          _cameraError = true;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _isFrontCamera = camera.lensDirection == CameraLensDirection.front;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _cameraController!.initialize();

      _gestureRecognizer = await GestureRecognizer.getInstance();
      _gestureRecognizer!.reset();
      _gestureRecognizer!.setPredictionFilter(
        minimumConfidence: AppConstants.quizPredictionConfidence,
        minimumMargin: AppConstants.quizPredictionMargin,
        windowSize: AppConstants.quizPredictionWindowSize,
        requiredMatches: AppConstants.quizPredictionRequiredMatches,
      );

      await _cameraController!.startImageStream(_onImage);

      if (mounted) setState(() {
        _cameraReady = true;
        _cameraInitializing = false;
      });
    } catch (e) {
      debugPrint('[QuizCamera] Error: $e');
      if (mounted) setState(() {
        _cameraInitializing = false;
        _cameraError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kamera tidak tersedia'),
            action: SnackBarAction(label: 'Coba Lagi', onPressed: _initCamera),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onImage(CameraImage image) {
    if (!_quizStarted || _provider.gameOver || _gestureRecognizer == null || _cameraController == null) {
      return;
    }
    if (_frameProcessing) return;
    _frameProcessing = true;
    final camera = _cameraController!.description;
    _gestureRecognizer!.processFrame(image, camera).then((result) {
      _frameProcessing = false;
      if (!mounted) return;
      if (result.detectedLetter != null) {
        _isDetecting = true;
        _provider.onLetterDetected(
          result.detectedLetter!,
          result.confidence,
          method: result.recognitionMethod,
          description: result.description,
          status: result.handsDetected ? 'READY' : 'NO HAND',
        );
        debugPrint('[QUIZ] letter=${result.detectedLetter} conf=${result.confidence.toStringAsFixed(3)} method=${result.recognitionMethod}');
      } else {
        _isDetecting = false;
        _provider.updateDetectionStatus(
          method: result.recognitionMethod,
          description: result.description,
          status: result.handsDetected ? 'PROCESSING' : 'NO HAND',
        );
        debugPrint('[QUIZ STATUS] ${result.handsDetected ? "PROCESSING" : "NO HAND"}');
      }
    });
  }

  Future<void> _switchCamera() async {
    try {
      final cameras = await availableCameras();
      final newLens = _isFrontCamera ? CameraLensDirection.back : CameraLensDirection.front;
      final newCamera = cameras.firstWhere(
        (c) => c.lensDirection == newLens,
        orElse: () => _isFrontCamera ? cameras.last : cameras.first,
      );

      final oldController = _cameraController;
      _cameraController = null;

      await oldController?.stopImageStream();
      await oldController?.dispose();

      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_onImage);

      if (mounted) setState(() => _isFrontCamera = !_isFrontCamera);
    } catch (e) {
      debugPrint('[QuizCamera] Switch error: $e');
    }
  }

  void _startQuiz() {
    setState(() => _quizStarted = true);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_provider.remainingSeconds <= 0) {
        _endGame();
      } else {
        _provider.tick();
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (!_quizStarted) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Quiz?'),
        content: const Text('Progress tidak akan disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _confirmEndGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesai Quiz?'),
        content: const Text('Quiz akan diakhiri dan ditampilkan hasil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endGame();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Future<void> _endGame() async {
    _countdownTimer?.cancel();
    _provider.endGame();
    await _disposeCamera();

    if (!mounted) return;

    final score = _provider.calculateFinalScore();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPage(
          score: score,
          category: widget.category,
          wordsCompleted: _provider.wordsCompleted,
          totalWords: _provider.words.length,
          totalAttempts: _provider.totalAttempts,
          correctAttempts: _provider.correctAttempts,
          comboCount: _provider.comboCount,
          remainingSeconds: _provider.remainingSeconds,
          timeLimitSeconds: widget.timeLimitSeconds,
        ),
      ),
    );
  }

  Future<void> _disposeCamera() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
    _gestureRecognizer = null;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(_disposeCamera());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz BISINDO')),
        body: _cameraError
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Kamera tidak tersedia',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pastikan izin kamera diberikan.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _initCamera,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_quizStarted,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onWillPop().then((canPop) {
          if (canPop && mounted) {
            Navigator.pop(context);
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz BISINDO'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_quizStarted) {
                _onWillPop().then((canPop) {
                  if (canPop && mounted) Navigator.pop(context);
                });
              } else {
                Navigator.pop(context);
              }
            },
            tooltip: 'Kembali',
          ),
          actions: [
            if (_quizStarted)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _confirmEndGame,
                tooltip: 'Selesai',
              ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _provider,
          builder: (context, _) {
            return SafeArea(
              child: Column(
                children: [
                  if (_quizStarted) ...[
                    TimerWidget(
                      remainingSeconds: _provider.remainingSeconds,
                      totalSeconds: widget.timeLimitSeconds,
                    ),
                    const SizedBox(height: 8),
                    ScoreWidget(
                      score: _provider.score,
                      comboCount: _provider.comboCount,
                      wordsCompleted: _provider.wordsCompleted,
                    ),
                    const SizedBox(height: 12),
                    ProgressWordWidget(
                      letters: _provider.wordLetters,
                      currentIndex: _provider.currentLetterIndex,
                      targetLetter: _provider.currentTargetLetter,
                      onCooldown: _provider.onCooldown,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Expanded(child: _buildCameraPreview()),
                  if (_quizStarted) ...[
                    _buildDetectedLetter(),
                    if (_provider.showingHint) _buildHintBanner(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final previewSize = controller.value.previewSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final previewHeight = constraints.maxWidth < 420 ? 300.0 : 360.0;

          return SizedBox(
            height: previewHeight,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: previewHeight,
                    color: Colors.black,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: previewSize?.height ?? previewHeight,
                        height: previewSize?.width ?? previewHeight,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, .12),
                  child: FractionallySizedBox(
                    widthFactor: .64,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isDetecting ? Colors.green : Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Camera switch button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _switchCamera,
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                // Camera indicator
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFrontCamera
                              ? Icons.camera_front
                              : Icons.camera_rear,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isFrontCamera ? 'Depan' : 'Belakang',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_quizStarted)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pan_tool, size: 48, color: Colors.white70),
                          const SizedBox(height: 12),
                          Text(
                            'Pilih posisi tangan',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Letakkan tangan di dalam kotak',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _startQuiz,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text('Mulai Quiz'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    if (method.isEmpty) return const SizedBox.shrink();
    final isAi = method == 'ai';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAi
            ? Colors.deepPurple.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAi ? 'AI' : 'Rule',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isAi ? Colors.deepPurple : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _buildDetectedLetter() {
    final result = _provider.lastDetectedLetter;
    final confidence = _provider.lastConfidence;
    final method = _provider.recognitionMethod;
    final description = _provider.description;
    final hasResult = result != null && result.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasResult
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasResult
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                hasResult ? Icons.check_circle : Icons.search,
                color: hasResult ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasResult
                      ? 'Huruf Terdeteksi'
                      : (_provider.status == 'PROCESSING'
                          ? 'Tahan tangan di dalam kotak...'
                          : 'Tidak ada tangan'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: hasResult ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (hasResult) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: Center(
                    child: Text(
                      result,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildMethodBadge(method),
                        ],
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHintBanner() {
    final hint = _quizService.getHint(_provider.currentTargetLetter);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => _provider.skipLetter(),
            child: const Text('Lewati'),
          ),
        ],
      ),
    );
  }
}
