import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  // Domains that send Access-Control-Allow-Origin: * natively
  static const _corsNativeDomains = [
    'supabase.co',
    'rest.ensembl.org',
    'grch37.rest.ensembl.org',
    'rest.uniprot.org',
    'alphafold.ebi.ac.uk',
    'www.ebi.ac.uk',          // ChEMBL, InterPro, QuickGO
    'string-db.org',
    'gnomad.broadinstitute.org',
    'spliceailookup.broadinstitute.org',
    'gtexportal.org',
    'www.encodeproject.org',
    'eutils.ncbi.nlm.nih.gov',
    'jaspar.elixir.no',
    'data.4dnucleome.org',
    'api.genome.ucsc.edu',
    'www.pgscatalog.org',
    'api.gdc.cancer.gov',
    'clinicaltrials.gov',
  ];

  static String _proxiedUrl(String url) {
    if (!kIsWeb) return url;
    // Skip proxy for APIs that support CORS natively
    for (final domain in _corsNativeDomains) {
      if (url.contains(domain)) return url;
    }
    // Only proxy APIs that lack CORS headers (e.g., KEGG)
    return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
  }

  static Future<T> get<T>(String url, {
    Map<String, dynamic>? params,
    int maxRetries = 3,
  }) async {
    if (await _isOffline()) {
      throw const NetworkError('No internet connection. Demo mode works offline.');
    }
    
    String targetUrl = url;
    if (params != null && params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      final separator = url.contains('?') ? '&' : '?';
      targetUrl = '$url$separator$queryString';
    }
    final finalUrl = _proxiedUrl(targetUrl);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get(finalUrl);
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
    final finalUrl = _proxiedUrl(url);
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.post(finalUrl, data: body);
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
    String targetUrl = url;
    if (params != null && params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      final separator = url.contains('?') ? '&' : '?';
      targetUrl = '$url$separator$queryString';
    }
    final finalUrl = _proxiedUrl(targetUrl);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get(finalUrl,
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
