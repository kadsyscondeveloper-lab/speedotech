// lib/services/tech_auth_service.dart
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/job_model.dart';

class AuthResult {
  final bool            success;
  final String?         error;
  final TechnicianInfo? technician;

  const AuthResult({required this.success, this.error, this.technician});
}

class TechAuthService {
  static final TechAuthService _instance = TechAuthService._internal();
  factory TechAuthService() => _instance;
  TechAuthService._internal();

  final _api     = ApiClient();
  final _storage = StorageService();

  bool    get isLoggedIn => _storage.hasToken;
  String? get techName   => _storage.techName;

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _api.post('/technician/auth/login', data: {
        'phone':    phone.trim(),
        'password': password,
      });

      final data  = res.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final tech  = TechnicianInfo.fromJson(
          data['technician'] as Map<String, dynamic>);

      await _storage.saveToken(token);
      await _storage.saveTechInfo(
        id:         tech.id,
        phone:      tech.phone,
        name:       tech.name,
        employeeId: tech.employeeId,
      );

      return AuthResult(success: true, technician: tech);
    } on DioException catch (e) {
      return AuthResult(
          success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Me ────────────────────────────────────────────────────────────────────

  Future<TechnicianInfo?> getMe() async {
    try {
      final res  = await _api.get('/technician/auth/me');
      final data = res.data['data'] as Map<String, dynamic>;
      return TechnicianInfo.fromJson(
          data['technician'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Change password ───────────────────────────────────────────────────────

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _api.post('/technician/auth/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      return const AuthResult(success: true);
    } on DioException catch (e) {
      return AuthResult(
          success: false, error: ApiException.fromDio(e).message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async => _storage.clearAll();
}
