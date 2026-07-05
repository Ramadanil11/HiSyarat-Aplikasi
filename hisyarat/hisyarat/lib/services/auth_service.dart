import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/database_helper.dart';
import 'api_client.dart';

class UserModel {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;
  final String role;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.passwordHash = '',
    this.salt = '',
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as int?,
    name:
        map['name'] as String? ??
        map['username'] as String? ??
        map['full_name'] as String? ??
        '',
    email: map['email'] as String? ?? '',
    passwordHash: map['password_hash'] as String? ?? '',
    salt: map['salt'] as String? ?? '',
    role: map['role'] as String? ?? 'learner',
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'username': name,
    'full_name': name,
    'email': email,
    'password_hash': passwordHash,
    'salt': salt,
    'role': role,
    'created_at': createdAt.toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? salt,
    String? role,
    DateTime? createdAt,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );
}

class SessionModel {
  final String token;
  final int userId;
  final DateTime createdAt;
  final DateTime expiresAt;

  const SessionModel({
    required this.token,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AuthEmailNotVerifiedException implements Exception {
  final String email;
  const AuthEmailNotVerifiedException(this.email);
}

class AuthException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const AuthException(this.code, this.message, {this.statusCode});

  factory AuthException.fromResponse(int statusCode, String responseBody) {
    String? message;
    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      final errors = body['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            message = value.first.toString();
            break;
          }
        }
      }
      message ??= body['message']?.toString();
    } catch (_) {
      // Fall back to a status-based message when the backend returns non-JSON.
    }

    return AuthException(
      'http_$statusCode',
      message ?? _messageForStatus(statusCode),
      statusCode: statusCode,
    );
  }

  static String _messageForStatus(int statusCode) {
    if (statusCode >= 500) {
      return 'Server HiSyarat sedang bermasalah. Coba lagi nanti.';
    }
    return 'Permintaan autentikasi gagal (HTTP $statusCode).';
  }

  @override
  String toString() => message;
}

class AuthService {
  AuthService({DatabaseHelper? database, ApiClient? api})
    : _db = database ?? DatabaseHelper(),
      _api = api ?? ApiClient.instance;

  final DatabaseHelper _db;
  final ApiClient _api;
  static final Map<String, int> _sessions = {};

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _api.post('/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
        'device_name': 'hisyarat-mobile',
      });
      if (response.statusCode != 200) {
        throw AuthException.fromResponse(response.statusCode, response.body);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String? ?? '';
      try {
        await _api.saveToken(token);
      } catch (_) {
        // Token storage failure is non-fatal
      }
      final user = await _upsertLocalUser(
        Map<String, dynamic>.from(body['user'] as Map? ?? {}),
      );
      _sessions[token] = user.id ?? 0;
      return {'user': user, 'token': token};
    } on AuthException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthException(e.code, e.message);
    } on TimeoutException {
      throw const AuthException(
        'timeout',
        'Koneksi ke server timeout. Periksa koneksi internet Anda.',
      );
    } on SocketException {
      throw const AuthException(
        'network',
        'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
      );
    } on http.ClientException {
      throw const AuthException(
        'network',
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } on FormatException {
      throw const AuthException(
        'invalid_response',
        'Respons server tidak valid.',
      );
    } on HandshakeException {
      throw const AuthException(
        'ssl_error',
        'Gagal koneksi aman ke server. Coba periksa tanggal/jam HP.',
      );
    } catch (_) {
      throw const AuthException('unknown', 'Terjadi kesalahan saat login.');
    }
  }

  Future<UserModel?> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await _api.post('/register', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
        'role': role,
      });
      if (response.statusCode != 201) {
        throw AuthException.fromResponse(response.statusCode, response.body);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      try {
        await _api.saveToken(body['token'] as String? ?? '');
      } catch (_) {
        // Token storage failure is non-fatal; continue with local user
      }
      return _upsertLocalUser(Map<String, dynamic>.from(body['user'] as Map? ?? {}));
    } on AuthException {
      rethrow;
    } on ApiException catch (e) {
      throw AuthException(e.code, e.message);
    } on TimeoutException {
      throw const AuthException(
        'timeout',
        'Koneksi ke server timeout. Periksa koneksi internet Anda.',
      );
    } on SocketException {
      throw const AuthException(
        'network',
        'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
      );
    } on http.ClientException {
      throw const AuthException(
        'network',
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } on FormatException {
      throw const AuthException(
        'invalid_response',
        'Respons server tidak valid.',
      );
    } on HandshakeException {
      throw const AuthException(
        'ssl_error',
        'Gagal koneksi aman ke server. Coba periksa tanggal/jam HP.',
      );
    } catch (_) {
      throw const AuthException(
        'unknown',
        'Terjadi kesalahan saat registrasi.',
      );
    }
  }

  Future<void> logout(String token) async {
    if (!_sessions.containsKey(token)) return;
    try {
      await _api.post('/logout', const {});
    } finally {
      _sessions.remove(token);
      await _api.clearToken();
    }
  }

  Future<void> signOut() async {
    final token = await _api.token;
    if (token != null) await logout(token);
  }

  int? validateSession(String token) => _sessions[token];
  void logoutAll(int userId) => _sessions.removeWhere((_, id) => id == userId);

  Future<String?> requestPasswordReset(String email) async {
    try {
      final response = await _api.post('/v1/password/forgot', {
        'email': email.trim().toLowerCase(),
      });
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['message'] as String? ?? 'Kode reset telah dikirim ke email.';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String password,
  ) async {
    try {
      final response = await _api.post('/v1/password/reset', {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'password': password,
        'password_confirmation': password,
      });
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async => false;

  Future<UserModel?> getUserFromLocalDb() async {
    final rows = await _db.query('users', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<void> restoreSession(String token) async {
    _sessions[token] = 0;
  }

  Future<UserModel?> getUserById(int id) async {
    final row = await _db.queryById('users', id);
    return row == null ? null : UserModel.fromMap(row);
  }

  Future<int> getTotalUserCount() => _db.count('users');

  Future<UserModel> _upsertLocalUser(Map<String, dynamic> remote) async {
    final email = (remote['email'] as String? ?? '').toLowerCase();
    final existing = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    final placeholder = sha256
        .convert(utf8.encode('laravel:$email'))
        .toString();
    final user = UserModel(
      id: existing.isEmpty ? null : existing.first['id'] as int?,
      name: remote['name'] as String? ?? email,
      email: email,
      passwordHash: placeholder,
      salt: 'laravel',
      role: remote['role'] as String? ?? 'learner',
      createdAt:
          DateTime.tryParse(remote['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
    if (existing.isEmpty) {
      return user.copyWith(id: await _db.insert('users', user.toMap()));
    }
    await _db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }
}
