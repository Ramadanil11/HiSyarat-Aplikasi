import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ─── State ────────────────────────────────────────────────────────────────
  UserModel? _currentUser;
  String? _sessionToken;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null && _sessionToken != null;
  String? get errorMessage => _errorMessage;

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      if (result != null) {
        _currentUser = result['user'] as UserModel;
        _sessionToken = result['token'] as String;
        SyncService.instance.syncPending();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email atau password salah';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthEmailNotVerifiedException {
      _errorMessage =
          'Email belum diverifikasi. Link verifikasi sudah dikirim ulang.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat login';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<bool> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(name, email, password, role);

      if (user != null) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            'Registrasi gagal. Email atau username sudah terdaftar.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat registrasi';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  void logout() {
    if (_sessionToken != null) {
      _authService.logout(_sessionToken!);
    }
    _currentUser = null;
    _sessionToken = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Auto Login (Persist Login) ───────────────────────────────────────────

  Future<bool> tryAutoLogin() async {
    final api = ApiClient.instance;
    final token = await api.token;
    if (token == null || token.isEmpty) return false;

    // Try online validation first
    try {
      final response = await api.get('/v1/me');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = body['data'] as Map<String, dynamic>? ?? body;
        _currentUser = UserModel.fromMap(userData);
        _sessionToken = token;
        await _authService.restoreSession(token);
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Network error — fall back to offline
    }

    // Offline fallback: load user from local database
    final localUser = await _authService.getUserFromLocalDb();
    if (localUser != null) {
      _currentUser = localUser;
      _sessionToken = token;
      await _authService.restoreSession(token);
      notifyListeners();
      return true;
    }

    return false;
  }

  // ─── Validate Session ─────────────────────────────────────────────────────

  bool validateSession() {
    if (_sessionToken == null) return false;
    final userId = _authService.validateSession(_sessionToken!);
    if (userId == null) {
      _currentUser = null;
      _sessionToken = null;
      notifyListeners();
      return false;
    }
    return true;
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  Future<String?> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final code = await _authService.requestPasswordReset(email);
      _isLoading = false;
      if (code == null) {
        _errorMessage = 'Format email tidak valid';
      }
      notifyListeners();
      return code;
    } catch (e) {
      _errorMessage = 'Gagal mengirim link reset password';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.resetPassword(
        email,
        code,
        newPassword,
      );
      _isLoading = false;
      if (!success) {
        _errorMessage =
            'Gagal reset password. Kode salah atau password terlalu pendek.';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Change Password ──────────────────────────────────────────────────────

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser?.id == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.changePassword(
        _currentUser!.id!,
        oldPassword,
        newPassword,
      );
      _isLoading = false;
      if (!success) {
        _errorMessage = 'Password lama salah atau password baru terlalu pendek';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Clear Error ──────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
