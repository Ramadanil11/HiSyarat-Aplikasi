import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'core/themes.dart';
import 'services/auth_service.dart';
import 'services/camera/camera_service.dart';
import 'services/dataset_capture_service.dart';

class DatasetCollectorPage extends StatefulWidget {
  final UserModel user;
  const DatasetCollectorPage({super.key, required this.user});

  @override
  State<DatasetCollectorPage> createState() => _DatasetCollectorPageState();
}

class _DatasetCollectorPageState extends State<DatasetCollectorPage> {
  final CameraService _camera = CameraService();
  final DatasetCaptureService _captureService = DatasetCaptureService();
  final TextEditingController _signerController = TextEditingController();
  final String _sessionUuid = const Uuid().v4();

  String _letter = 'A';
  int _target = 30;
  int _captured = 0;
  bool _ready = false;
  bool _capturing = false;
  bool _automatic = false;
  bool _consent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signerController.text = widget.user.name;
    _initialize();
  }

  Future<void> _initialize() async {
    await _camera.initialize();
    final ready = await _camera.startCamera(resolution: ResolutionPreset.high);
    if (!mounted) return;
    setState(() => _ready = ready);
  }

  @override
  void dispose() {
    _automatic = false;
    _signerController.dispose();
    unawaited(_camera.dispose());
    super.dispose();
  }

  Future<void> _switchCamera() async {
    if (_capturing || _automatic) return;
    setState(() => _ready = false);
    await _camera.switchCamera();
    if (!mounted) return;
    setState(() => _ready = _camera.isInitialized);
  }

  Future<bool> _captureOne() async {
    final controller = _camera.controller;
    final signer = _signerController.text.trim();
    if (!_ready || controller == null || _capturing) return false;
    if (!_consent) {
      _message('Konfirmasi persetujuan pemeraga terlebih dahulu.', error: true);
      return false;
    }
    if (signer.length < 2) {
      _message('Isi ID pemeraga minimal 2 karakter.', error: true);
      return false;
    }
    setState(() {
      _capturing = true;
      _error = null;
    });
    File? photo;
    try {
      final capture = await controller.takePicture();
      photo = File(capture.path);
      await _captureService.upload(
        photo: photo,
        uuid: const Uuid().v4(),
        signerId: signer,
        letter: _letter,
        sessionUuid: _sessionUuid,
        cameraLens: _camera.isFrontCamera ? 'front' : 'back',
      );
      if (!mounted) return true;
      setState(() => _captured++);
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(
        () => _error = 'Foto gagal dikirim. Periksa server dan koneksi.',
      );
      _message(_error!, error: true);
      return false;
    } finally {
      if (photo != null && await photo.exists()) {
        await photo.delete();
      }
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _startAutomatic() async {
    if (_automatic) {
      setState(() => _automatic = false);
      return;
    }
    if (_captured >= _target) {
      setState(() => _captured = 0);
    }
    setState(() => _automatic = true);
    while (mounted && _automatic && _captured < _target) {
      final uploaded = await _captureOne();
      if (!uploaded) {
        if (mounted) setState(() => _automatic = false);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 850));
    }
    if (!mounted) return;
    setState(() => _automatic = false);
    if (_captured >= _target) {
      _message('Target $_target foto huruf $_letter selesai.');
    }
  }

  void _selectLetter(String letter) {
    if (_capturing || _automatic) return;
    setState(() {
      _letter = letter;
      _captured = 0;
      _error = null;
    });
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koleksi Dataset BISINDO')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _signerController,
            enabled: !_automatic && !_capturing,
            decoration: const InputDecoration(
              labelText: 'ID pemeraga',
              hintText: 'Contoh: pemeraga-09',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _target,
                  decoration: const InputDecoration(labelText: 'Target foto'),
                  items: const [20, 30, 50, 100]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value foto'),
                        ),
                      )
                      .toList(),
                  onChanged: _automatic
                      ? null
                      : (value) => setState(() => _target = value ?? 30),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: _captured / _target,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Text('$_captured/$_target'),
            ],
          ),
          const SizedBox(height: 14),
          _buildPreview(),
          const SizedBox(height: 14),
          Text(
            'Huruf $_letter',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildLetters(),
          const SizedBox(height: 14),
          CheckboxListTile(
            value: _consent,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Pemeraga menyetujui foto dipakai untuk training',
            ),
            onChanged: _automatic
                ? null
                : (value) => setState(() => _consent = value ?? false),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _capturing || _automatic ? null : _captureOne,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Satu Foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _capturing && !_automatic ? null : _startAutomatic,
                  icon: Icon(_automatic ? Icons.stop : Icons.play_arrow),
                  label: Text(_automatic ? 'Berhenti' : 'Mulai Otomatis'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final controller = _camera.controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 3 / 4,
        child: ColoredBox(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final size = controller.value.previewSize;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size?.height ?? 480,
                height: size?.width ?? 640,
                child: CameraPreview(controller),
              ),
            ),
            Center(
              child: FractionallySizedBox(
                widthFactor: .65,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filledTonal(
                onPressed: _switchCamera,
                icon: const Icon(Icons.cameraswitch_outlined),
                tooltip: 'Ganti kamera',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetters() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(26, (index) {
        final letter = String.fromCharCode(65 + index);
        return ChoiceChip(
          label: Text(letter),
          selected: _letter == letter,
          onSelected: (_) => _selectLetter(letter),
        );
      }),
    );
  }
}
