import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/database_helper.dart';
import 'api_client.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final DatabaseHelper _db = DatabaseHelper();
  final ApiClient _api = ApiClient.instance;
  bool _syncing = false;
  bool _observingLifecycle = false;
  final ValueNotifier<SyncStatus> status = ValueNotifier(
    const SyncStatus(pending: 0, failed: 0, syncing: false),
  );

  void startLifecycleSync() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(_SyncLifecycleObserver(this));
    _observingLifecycle = true;
    unawaited(_refreshStatus(syncing: false));
  }

  Future<bool> syncPending() async {
    if (_syncing || await _api.token == null) return false;
    _syncing = true;
    await _refreshStatus(syncing: true);
    try {
      await _syncLegacyRecords();
      await _syncDetections();
      await _syncCompositions();
      return true;
    } catch (error) {
      debugPrint('[SyncService] Sinkronisasi ditunda: $error');
      return false;
    } finally {
      _syncing = false;
      await _refreshStatus(syncing: false);
    }
  }

  Future<void> _syncLegacyRecords() async {
    final translations = await _pending('translations');
    final histories = await _pending('translation_history');
    final feedbacks = await _pending('feedbacks');
    if (translations.isEmpty && histories.isEmpty && feedbacks.isEmpty) return;
    final response = await _api.post('/sync/push', {
      'translations': translations,
      'translation_histories': histories,
      'feedbacks': feedbacks,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) return;
    await _markSynced('translations', translations, 'sync_uuid');
    await _markSynced('translation_history', histories, 'sync_uuid');
    await _markSynced('feedbacks', feedbacks, 'sync_uuid');
  }

  Future<void> _syncDetections() async {
    final records = await _pending('detection_uploads');
    for (final record in records) {
      try {
        final file = File(record['photo_path'] as String);
        if (!await file.exists()) {
          await _markDetectionError(record, 'Foto lokal tidak ditemukan.');
          continue;
        }
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.apiBaseUrl}/detections'),
        );
        request.headers.addAll(await _api.headers(json: false));
        request.fields.addAll({
          'uuid': record['uuid'].toString(),
          'predicted_label': record['predicted_label'].toString(),
          'confirmed_label': record['confirmed_label'].toString(),
          'confidence': record['confidence'].toString(),
          'top_predictions': record['top_predictions']?.toString() ?? '{}',
          'session_uuid': record['session_uuid']?.toString() ?? '',
          'captured_at': record['captured_at'].toString(),
          'model_name': record['model_name']?.toString() ?? '',
          'model_version': record['model_version']?.toString() ?? '',
        });
        request.files.add(
          await http.MultipartFile.fromPath('photo', file.path),
        );
        final response = await request.send().timeout(
          Duration(milliseconds: AppConstants.connectionTimeout),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _markSynced('detection_uploads', [record], 'uuid');
          await file.delete();
        } else {
          final body = await response.stream.bytesToString();
          await _markDetectionError(
            record,
            response.statusCode == 401
                ? 'Sesi login berakhir. Silakan login kembali.'
                : 'Server menolak upload (${response.statusCode}): $body',
          );
        }
      } catch (error) {
        await _markDetectionError(record, 'Upload gagal: $error');
      }
    }
  }

  Future<void> _markDetectionError(
    Map<String, dynamic> record,
    String message,
  ) => _db.update(
    'detection_uploads',
    {
      'sync_error': message.length > 240 ? message.substring(0, 240) : message,
      'last_sync_attempt_at': DateTime.now().toUtc().toIso8601String(),
    },
    where: 'uuid = ?',
    whereArgs: [record['uuid']],
  );

  Future<void> _refreshStatus({required bool syncing}) async {
    final pending = await _db.query(
      'detection_uploads',
      where: "sync_status = 'pending'",
    );
    status.value = SyncStatus(
      pending: pending.length,
      failed: pending.where((row) => row['sync_error'] != null).length,
      syncing: syncing,
    );
  }

  Future<void> _syncCompositions() async {
    final records = await _pending('composition_uploads');
    for (final record in records) {
      final response = await _api.post('/compositions', {
        'uuid': record['uuid'],
        'session_uuid': record['session_uuid'],
        'text': record['text'],
        'detection_uuids': jsonDecode(record['detection_uuids'] as String),
        'composed_at': record['composed_at'],
      });
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _markSynced('composition_uploads', [record], 'uuid');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _pending(String table) =>
      _db.query(table, where: "sync_status = 'pending'", limit: 100);

  Future<void> _markSynced(
    String table,
    List<Map<String, dynamic>> records,
    String key,
  ) async {
    for (final record in records) {
      await _db.update(
        table,
        {'sync_status': 'synced'},
        where: '$key = ?',
        whereArgs: [record[key]],
      );
    }
  }
}

class SyncStatus {
  final int pending;
  final int failed;
  final bool syncing;
  const SyncStatus({
    required this.pending,
    required this.failed,
    required this.syncing,
  });
}

class _SyncLifecycleObserver extends WidgetsBindingObserver {
  final SyncService service;
  _SyncLifecycleObserver(this.service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(service.syncPending());
  }
}
