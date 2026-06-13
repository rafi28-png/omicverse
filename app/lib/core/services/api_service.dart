import 'dart:async';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/app_error.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ));

  static Dio get client => _dio;

  // FIX NEW-01: connectivity_plus returns List<ConnectivityResult>
  static Future<bool> _isOffline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  static Future<T> get<T>(String url, {
    Map<String, dynamic>? params,
    int maxRetries = 3,
  }) async {
    if (await _isOffline()) {
      throw const NetworkError('No internet connection. Demo mode works offline.');
    }
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get(url, queryParameters: params);
        if (response.data == null) throw const ParseError('Empty response');
        return response.data as T;
      } on DioException catch (e) {
        if (attempt == maxRetries) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            throw const TimeoutError();
          }
          if (e.response?.statusCode == 429) {
            final after = int.tryParse(
              e.response?.headers.value('retry-after') ?? '60') ?? 60;
            throw RateLimitError(after);
          }
          if (e.response?.statusCode == 404) throw const NotFoundError();
          throw const NetworkError('Connection failed. Please try again.');
        }
        await Future.delayed(Duration(seconds: [1, 2, 4][attempt - 1]));
      }
    }
    throw const NetworkError('Request failed after multiple attempts.');
  }

  // GraphQL POST (for gnomAD)
  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body, {
    int maxRetries = 3,
  }) async {
    if (await _isOffline()) {
      throw const NetworkError('No internet connection.');
    }
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.post(url, data: body);
        return response.data as Map<String, dynamic>;
      } on DioException {
        if (attempt == maxRetries) throw const NetworkError('GraphQL request failed.');
        await Future.delayed(Duration(seconds: [1, 2, 4][attempt - 1]));
      }
    }
    throw const NetworkError('Request failed after multiple attempts.');
  }

  /// GET request returning raw text (for APIs like KEGG that return plain text)
  static Future<String> getRaw(String url, {
    Map<String, dynamic>? params,
    int maxRetries = 3,
  }) async {
    if (await _isOffline()) {
      throw const NetworkError('No internet connection.');
    }
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get(url,
          queryParameters: params,
          options: Options(responseType: ResponseType.plain),
        );
        return response.data.toString();
      } on DioException {
        if (attempt == maxRetries) throw const NetworkError('Request failed.');
        await Future.delayed(Duration(seconds: [1, 2, 4][attempt - 1]));
      }
    }
    throw const NetworkError('Request failed after multiple attempts.');
  }
}

Future<T> safeApiCall<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on AppError {
    rethrow;
  } catch (e) {
    throw NetworkError('Unexpected error: ${e.runtimeType}');
  }
}
