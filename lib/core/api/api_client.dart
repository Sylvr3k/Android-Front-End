import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../storage/secure_storage.dart';

/// A single Dio instance shared by every repository. It knows how to:
/// - attach the Sanctum bearer token to every request,
/// - normalize every failure into an [AppFailure] the UI can render,
/// - and notify the rest of the app when the session has expired.
class ApiClient {
  ApiClient(this._storage) : _dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthenticated?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStorage _storage;

  /// Set by the auth layer so a 401 from anywhere can force a clean logout.
  void Function()? onUnauthenticated;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    return _unwrap(() => _dio.get(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    return _unwrap(() => _dio.post(path, data: data));
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) async {
    return _unwrap(() => _dio.put(path, data: data));
  }

  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? data}) async {
    return _unwrap(() => _dio.delete(path, data: data));
  }

  /// Multipart upload — e.g. a profile photo. [fileBytes] is used instead of
  /// a file path so this works identically on web (where there is no real
  /// filesystem path) and on Android/iOS.
  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String fieldName,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(fileBytes, filename: filename),
    });

    return _unwrap(() => _dio.post(path, data: form));
  }

  Future<Map<String, dynamic>> _unwrap(Future<Response> Function() request) async {
    try {
      final response = await request();
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AppFailure _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppFailure.timeout();
      case DioExceptionType.connectionError:
        return AppFailure.network();
      default:
        break;
    }

    final response = error.response;

    if (response == null) {
      return AppFailure.network();
    }

    final data = response.data;
    final body = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

    final message = body['message'] as String? ?? _defaultMessageFor(response.statusCode);

    Map<String, List<String>>? fieldErrors;
    final errors = body['errors'];
    if (errors is Map) {
      fieldErrors = errors.map(
        (key, value) => MapEntry(key.toString(), List<String>.from((value as List).map((v) => v.toString()))),
      );
    }

    if (response.statusCode != null && response.statusCode! >= 500) {
      return AppFailure.server();
    }

    return AppFailure(message, fieldErrors: fieldErrors, statusCode: response.statusCode);
  }

  String _defaultMessageFor(int? statusCode) {
    return switch (statusCode) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You are not authorized to do that.',
      404 => 'We could not find what you were looking for.',
      409 => 'This action has already been completed.',
      422 => 'Please check the information you entered.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
