// lib/viewmodels/auth_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/tech_auth_service.dart';
import '../models/job_model.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final TechAuthService _service;

  AuthViewModel({TechAuthService? service})
      : _service = service ?? TechAuthService();

  // ── State ─────────────────────────────────────────────────────────────────

  AuthStatus    _status           = AuthStatus.idle;
  String?       _errorMessage;
  bool          _isPasswordVisible = false;
  TechnicianInfo? _technician;

  String _phone    = '';
  String _password = '';

  // ── Getters ───────────────────────────────────────────────────────────────

  AuthStatus    get status            => _status;
  String?       get errorMessage      => _errorMessage;
  bool          get isLoading         => _status == AuthStatus.loading;
  bool          get isPasswordVisible => _isPasswordVisible;
  TechnicianInfo? get technician      => _technician;

  // ── Setters ───────────────────────────────────────────────────────────────

  void setPhone(String v)    { _phone    = v.trim(); _clearError(); }
  void setPassword(String v) { _password = v;        _clearError(); }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login() async {
    if (_phone.isEmpty || _password.isEmpty) {
      _errorMessage = 'Please enter your phone number and password.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status       = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.login(phone: _phone, password: _password);

    if (result.success) {
      _technician = result.technician;
      _status     = AuthStatus.success;
      notifyListeners();
      return true;
    } else {
      _status       = AuthStatus.error;
      _errorMessage = result.error;
      notifyListeners();
      return false;
    }
  }

  void _clearError() {
    if (_errorMessage != null || _status == AuthStatus.error) {
      _errorMessage = null;
      _status       = AuthStatus.idle;
      notifyListeners();
    }
  }

  void resetState() {
    _status           = AuthStatus.idle;
    _errorMessage     = null;
    _isPasswordVisible = false;
    notifyListeners();
  }
}
