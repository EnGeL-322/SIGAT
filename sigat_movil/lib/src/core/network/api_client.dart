import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String baseUrl = AppConfig.apiBaseUrl, HttpClient? httpClient})
    : baseUrl = _trimSlash(baseUrl),
      _httpClient = httpClient ?? HttpClient();

  final String baseUrl;
  final HttpClient _httpClient;
  String? authToken;

  Future<Map<String, dynamic>> login(String email, String password) {
    return post('/auth/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) {
    return post('/auth/register', payload);
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) {
    return post('/auth/forgot-password', {'email': email});
  }

  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> payload) {
    return post('/auth/reset-password', payload);
  }

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) {
    return _send('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<List<Map<String, dynamic>>> list(String path) async {
    final response = await get(path);
    return listFromResponse(response);
  }

  Future<void> close() async {
    _httpClient.close(force: true);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _open(method, path);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    if (authToken?.isNotEmpty ?? false) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
    }

    if (body != null) {
      request.write(jsonEncode(body));
    }

    try {
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final rawBody = await utf8.decoder.bind(response).join();
      final decoded = _decodeBody(rawBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          messageFromResponse(decoded) ?? 'Error HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {'exito': true, 'mensaje': 'OK', 'datos': decoded};
    } on SocketException {
      throw ApiException('No se pudo conectar con el backend en $baseUrl');
    } on TimeoutException {
      throw ApiException('El backend tardo demasiado en responder');
    } on FormatException {
      throw ApiException('El backend devolvio una respuesta no valida');
    }
  }

  Future<HttpClientRequest> _open(String method, String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return _httpClient
        .openUrl(method, Uri.parse('$baseUrl$normalizedPath'))
        .timeout(const Duration(seconds: 12));
  }

  dynamic _decodeBody(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(rawBody);
  }

  static List<Map<String, dynamic>> listFromResponse(
    Map<String, dynamic> response,
  ) {
    final data = response['datos'] ?? response['data'] ?? response['content'];
    if (data is List) {
      return data
          .whereType<Object?>()
          .map(
            (item) =>
                item is Map ? Map<String, dynamic>.from(item) : {'valor': item},
          )
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic> mapFromResponse(Map<String, dynamic> response) {
    final data = response['datos'] ?? response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  static String? messageFromResponse(dynamic response) {
    if (response is Map) {
      return response['mensaje']?.toString() ?? response['message']?.toString();
    }
    return null;
  }

  static bool isSuccess(Map<String, dynamic> response) =>
      response['exito'] == true;

  static String _trimSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
