import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/database_helper.dart';
import 'sync_service.dart';

class DetectionService {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  Future<String?> queueConfirmedLetter({
    required int userId,
    required String predictedLabel,
    required String confirmedLabel,
    required double confidence,
    required Map<String, double> topPredictions,
    required String sessionUuid,
    required Uint8List? snapshotJpeg,
    required String modelName,
    required String modelVersion,
  }) async {
    if (snapshotJpeg == null) return null;
    final uuid = _uuid.v4();
    final directory = Directory(
      path.join(
        (await getApplicationDocumentsDirectory()).path,
        'pending_detections',
      ),
    );
    await directory.create(recursive: true);
    final photo = File(path.join(directory.path, '$uuid.jpg'));
    await photo.writeAsBytes(snapshotJpeg, flush: true);
    await _db.insert('detection_uploads', {
      'uuid': uuid,
      'user_id': userId,
      'predicted_label': predictedLabel,
      'confirmed_label': confirmedLabel,
      'confidence': confidence,
      'top_predictions': jsonEncode(topPredictions),
      'session_uuid': sessionUuid,
      'photo_path': photo.path,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'sync_status': 'pending',
      'model_name': modelName,
      'model_version': modelVersion,
      'sync_error': null,
    });
    unawaited(SyncService.instance.syncPending());
    return uuid;
  }

  Future<void> queueComposition({
    required int userId,
    required String sessionUuid,
    required String text,
    required List<String> detectionUuids,
  }) async {
    if (text.trim().isEmpty) return;
    await _db.insert('composition_uploads', {
      'uuid': _uuid.v4(),
      'user_id': userId,
      'session_uuid': sessionUuid,
      'text': text.trim(),
      'detection_uuids': jsonEncode(detectionUuids),
      'composed_at': DateTime.now().toUtc().toIso8601String(),
      'sync_status': 'pending',
    });
    unawaited(SyncService.instance.syncPending());
  }
}
