import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import 'api_client.dart';

class DatasetCaptureService {
  final ApiClient _api = ApiClient.instance;

  Future<void> upload({
    required File photo,
    required String uuid,
    required String signerId,
    required String letter,
    required String sessionUuid,
    required String cameraLens,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiBaseUrl}/dataset-captures'),
    );
    request.headers.addAll(await _api.headers(json: false));
    request.fields.addAll({
      'uuid': uuid,
      'signer_id': signerId,
      'letter': letter,
      'session_uuid': sessionUuid,
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'camera_lens': cameraLens,
    });
    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    final response = await request.send().timeout(
      Duration(milliseconds: AppConstants.connectionTimeout),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw Exception('Upload ditolak (${response.statusCode}): $body');
    }
  }
}
