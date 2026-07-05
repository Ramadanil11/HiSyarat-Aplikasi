import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException(this.code, this.message, {this.statusCode});

  factory ApiException.fromHttpError(Object error) {
    if (error is TimeoutException) {
      return const ApiException(
        'timeout',
        'Koneksi ke server timeout. Periksa koneksi internet Anda.',
      );
    }
    if (error is SocketException) {
      return const ApiException(
        'network',
        'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
      );
    }
    if (error is HandshakeException) {
      return const ApiException(
        'ssl_error',
        'Gagal koneksi aman ke server. Coba periksa tanggal/jam HP.',
      );
    }
    if (error is http.ClientException) {
      return const ApiException(
        'network',
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }
    return ApiException(
      'unknown',
      'Terjadi kesalahan. Silakan coba lagi.',
    );
  }

  factory ApiException.fromResponse(int statusCode) {
    if (statusCode >= 500) {
      return const ApiException(
        'server_error',
        'Server sedang mengalami gangguan. Silakan coba lagi.',
      );
    }
    if (statusCode == 401) {
      return const ApiException(
        'unauthorized',
        'Sesi login berakhir. Silakan login kembali.',
      );
    }
    if (statusCode == 403) {
      return const ApiException(
        'forbidden',
        'Anda tidak memiliki akses.',
      );
    }
    if (statusCode == 404) {
      return const ApiException(
        'not_found',
        'Data tidak ditemukan.',
      );
    }
    if (statusCode == 422) {
      return const ApiException(
        'validation',
        'Data yang dikirim tidak valid. Periksa kembali input Anda.',
      );
    }
    return ApiException(
      'http_$statusCode',
      'Permintaan gagal (HTTP $statusCode).',
    );
  }

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const _tokenKey = 'hisyarat_sanctum_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> get token => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, String>> headers({bool json = true}) async {
    final authToken = await token;
    return {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (json) 'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  Future<http.Response> get(String path) async {
    try {
      return await http
          .get(
            Uri.parse('${AppConstants.apiBaseUrl}$path'),
            headers: await headers(),
          )
          .timeout(Duration(milliseconds: AppConstants.receiveTimeout));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromHttpError(e);
    }
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            Uri.parse('${AppConstants.apiBaseUrl}$path'),
            headers: await headers(),
            body: jsonEncode(body),
          )
          .timeout(Duration(milliseconds: AppConstants.connectionTimeout));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromHttpError(e);
    }
  }
}
