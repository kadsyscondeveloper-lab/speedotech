// lib/core/app_config.dart
class AppConfig {
  AppConfig._();

  static const String baseUrl = 'http://103.88.81.7:3000/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String kAccessToken   = 'tech_access_token';
  static const String kTechId        = 'tech_id';
  static const String kTechPhone     = 'tech_phone';
  static const String kTechName      = 'tech_name';
  static const String kTechEmployeeId = 'tech_employee_id';
}
