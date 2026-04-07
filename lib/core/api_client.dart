// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'app_config.dart';
import 'storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() { _init(); }

  late final Dio _dio;
  final _storage = StorageService();

  Dio get dio => _dio;

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(LogInterceptor(
      requestBody:  true,
      responseBody: true,
      error:        true,
      logPrint:     (obj) => print('[API] $obj'),
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);
}

class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class ApiException implements Exception {
  final String message;
  final int?   statusCode;

  const ApiException({required this.message, this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return ApiException(
        message:    data['message'] as String? ?? 'Something went wrong',
        statusCode: e.response?.statusCode,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(message: 'Connection timed out. Please check your internet.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(message: 'Cannot reach server. Check your network.');
    }
    return ApiException(message: e.message ?? 'Unknown error', statusCode: e.response?.statusCode);
  }
}
