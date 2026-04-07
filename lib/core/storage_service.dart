// lib/core/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() must be called before use');
    return _prefs!;
  }

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async =>
      _p.setString(AppConfig.kAccessToken, token);

  String? get accessToken => _p.getString(AppConfig.kAccessToken);
  bool    get hasToken    => accessToken != null && accessToken!.isNotEmpty;

  // ── Technician info ───────────────────────────────────────────────────────

  Future<void> saveTechInfo({
    required int    id,
    required String phone,
    required String name,
    required String employeeId,
  }) async {
    await _p.setInt(   AppConfig.kTechId,         id);
    await _p.setString(AppConfig.kTechPhone,       phone);
    await _p.setString(AppConfig.kTechName,        name);
    await _p.setString(AppConfig.kTechEmployeeId,  employeeId);
  }

  int?    get techId         => _p.getInt(AppConfig.kTechId);
  String? get techPhone      => _p.getString(AppConfig.kTechPhone);
  String? get techName       => _p.getString(AppConfig.kTechName);
  String? get techEmployeeId => _p.getString(AppConfig.kTechEmployeeId);

  Future<void> clearAll() async => _p.clear();
}
