import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../offline/offline_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    String baseUrl = AppConfig.apiBaseUrl,
    HttpClient? httpClient,
    this.store,
  }) : baseUrl = _trimSlash(baseUrl),
       _httpClient = httpClient ?? HttpClient();

  final String baseUrl;
  final HttpClient _httpClient;
  String? authToken;

  /// Almacenamiento offline opcional. Si esta presente, las lecturas se
  /// cachean y las escrituras sin conexion se encolan automaticamente.
  final OfflineStore? store;

  /// Se invoca cuando el backend responde 401 (token invalido/expirado),
  /// para que la app pueda cerrar la sesion y volver al login.
  void Function()? onUnauthorized;

  /// Se invoca tras una operacion de red exitosa (senal de que hay conexion).
  void Function()? onOnline;

  /// Se invoca cuando una operacion no logra conectar (sin conexion).
  void Function()? onOffline;

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
    try {
      final result = await _sendOverNetwork(method, path, body: body);
      // Conexion exitosa: cachea las lecturas y avisa que hay internet.
      if (method == 'GET') {
        await store?.cachePut(path, result.rawBody);
      }
      onOnline?.call();
      return result.map;
    } on SocketException {
      return _handleOffline(method, path, body);
    } on TimeoutException {
      return _handleOffline(method, path, body);
    }
  }

  /// Reintenta una operacion directamente contra la red, SIN tocar la cola
  /// offline. Lo usa el servicio de sincronizacion para vaciar el outbox.
  Future<Map<String, dynamic>> sendRaw(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final result = await _sendOverNetwork(method, path, body: body);
    return result.map;
  }

  Future<_HttpResult> _sendOverNetwork(
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
        // Spring Security responde 403 (no 401) cuando falta o expira el token.
        // Fuera de los endpoints de autenticacion, tratamos 401 y 403 como
        // "sesion invalida": se cierra la sesion y se vuelve al login, en vez
        // de mostrar un "Error HTTP 403" crudo al usuario.
        final esAuth = path.startsWith('/auth');
        if (!esAuth &&
            (response.statusCode == 401 || response.statusCode == 403)) {
          onUnauthorized?.call();
          throw ApiException(
            'Tu sesion expiro o no es valida. Inicia sesion de nuevo.',
            statusCode: response.statusCode,
          );
        }
        throw ApiException(
          messageFromResponse(decoded) ?? 'Error HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final map = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{'exito': true, 'mensaje': 'OK', 'datos': decoded};
      return _HttpResult(map, rawBody);
    } on FormatException {
      throw ApiException('El backend devolvio una respuesta no valida');
    }
  }

  /// Gestiona una operacion cuando no hay conexion con el backend.
  ///
  /// - GET: devuelve la ultima copia guardada en cache, si existe.
  /// - POST/PUT/DELETE: encola la escritura y actualiza la cache local de
  ///   forma optimista para que el cambio se vea de inmediato.
  Future<Map<String, dynamic>> _handleOffline(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    onOffline?.call();

    final offlineStore = store;
    if (offlineStore == null) {
      throw ApiException('No se pudo conectar con el backend en $baseUrl');
    }

    if (method == 'GET') {
      final cached = await offlineStore.cacheGet(path);
      if (cached != null) {
        final decoded = _decodeBody(cached);
        if (decoded is Map<String, dynamic>) {
          return {...decoded, '_offline': true};
        }
        if (decoded is Map) {
          return {...Map<String, dynamic>.from(decoded), '_offline': true};
        }
        return {'exito': true, 'datos': decoded, '_offline': true};
      }
      throw ApiException(
        'Sin conexion y sin datos guardados todavia para mostrar.',
      );
    }

    // La autenticacion (login, registro, recuperacion) NO se encola: requiere
    // verificacion en el servidor, asi que sin conexion debe fallar de inmediato.
    if (path.startsWith('/auth')) {
      throw ApiException(
        'No hay conexion. Inicia sesion al menos una vez con internet.',
      );
    }

    return _enqueueOfflineWrite(offlineStore, method, path, body);
  }

  Future<Map<String, dynamic>> _enqueueOfflineWrite(
    OfflineStore offlineStore,
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final localId = -DateTime.now().millisecondsSinceEpoch;
    final collection = _collectionOf(path);

    await offlineStore.enqueue(
      method: method,
      path: path,
      collection: collection,
      payload: body,
      localId: localId,
    );
    await _patchCacheOptimistically(
      offlineStore,
      method: method,
      path: path,
      collection: collection,
      body: body,
      localId: localId,
    );

    return {
      'exito': true,
      'mensaje': 'Guardado sin conexion. Se sincronizara al recuperar internet.',
      'datos': {...?body, 'id': localId, '_pending': true},
      '_pending': true,
    };
  }

  /// Refleja en la cache local una escritura encolada, para que el listado
  /// del modulo muestre el cambio de inmediato aunque no haya internet.
  Future<void> _patchCacheOptimistically(
    OfflineStore offlineStore, {
    required String method,
    required String path,
    required String collection,
    Map<String, dynamic>? body,
    required int localId,
  }) async {
    final cached = await offlineStore.cacheGet(collection);
    if (cached == null) return;

    final decoded = _decodeBody(cached);
    if (decoded is! Map) return;
    final envelope = Map<String, dynamic>.from(decoded);
    final data = envelope['datos'] ?? envelope['data'];
    if (data is! List) return;
    final rows = data
        .whereType<Object?>()
        .map((item) => item is Map ? Map<String, dynamic>.from(item) : item)
        .toList();

    final targetId = _idFromPath(path);

    switch (method) {
      case 'POST':
        rows.add(_optimisticRow(collection, body, localId));
      case 'PUT':
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i];
          if (row is Map<String, dynamic> && _matchesId(row, targetId)) {
            rows[i] = {...row, ...?body, '_pending': true};
          }
        }
      case 'DELETE':
        rows.removeWhere(
          (row) => row is Map<String, dynamic> && _matchesId(row, targetId),
        );
    }

    envelope['datos'] = rows;
    await offlineStore.cachePut(collection, jsonEncode(envelope));
  }

  /// Construye una fila optimista a partir del payload enviado. Para ventas y
  /// compras (cuyo numero/IMEI los genera el servidor) deja marcas PENDIENTE.
  Map<String, dynamic> _optimisticRow(
    String collection,
    Map<String, dynamic>? body,
    int localId,
  ) {
    if (collection == '/ventas' || collection == '/compras') {
      final detalles = body?['detalles'];
      num total = 0;
      if (detalles is List) {
        for (final detail in detalles) {
          if (detail is Map) {
            final cantidad = num.tryParse('${detail['cantidad']}') ?? 0;
            final precio = num.tryParse('${detail['precioUnitario']}') ?? 0;
            total += cantidad * precio;
          }
        }
      }
      final numberKey = collection == '/ventas'
          ? 'numeroVenta'
          : 'numeroCompra';
      return {
        'id': localId,
        numberKey: 'PENDIENTE',
        'estado': 'PENDIENTE',
        'total': total,
        '_pending': true,
      };
    }
    return {...?body, 'id': localId, '_pending': true};
  }

  /// Devuelve la ruta de coleccion de una escritura: quita el id final.
  /// `/clientes/5` -> `/clientes`, `/clientes` -> `/clientes`.
  static String _collectionOf(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final segments = normalized.split('/');
    if (segments.length > 1 && int.tryParse(segments.last) != null) {
      segments.removeLast();
    }
    final joined = segments.join('/');
    return joined.isEmpty ? '/' : joined;
  }

  static int? _idFromPath(String path) {
    final segments = path.split('/');
    return segments.isEmpty ? null : int.tryParse(segments.last);
  }

  static bool _matchesId(Map<String, dynamic> row, int? id) {
    if (id == null) return false;
    final rowId = row['id'];
    if (rowId is int) return rowId == id;
    return int.tryParse('$rowId') == id;
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
      final raw =
          response['mensaje']?.toString() ?? response['message']?.toString();
      return _friendlyMessage(raw);
    }
    return null;
  }

  static bool isSuccess(Map<String, dynamic> response) =>
      response['exito'] == true;

  static String _trimSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String? _friendlyMessage(String? message) {
    if (message == null || message.trim().isEmpty) return message;

    final normalized = message.toLowerCase();
    if (normalized.contains('duplicate entry') ||
        normalized.contains('constraint') ||
        normalized.contains('could not execute statement')) {
      if (normalized.contains('email') || normalized.contains('usuario')) {
        return 'Ya existe un usuario con ese email';
      }
      if (normalized.contains('codigo')) {
        return 'Ya existe un registro con ese codigo';
      }
      if (normalized.contains('ruc')) {
        return 'Ya existe un proveedor con ese RUC';
      }
      if (normalized.contains('cedula')) {
        return 'Ya existe un cliente con esa cedula';
      }
      return 'No se pudo guardar. Revisa que los datos no esten duplicados.';
    }

    return message;
  }
}

class _HttpResult {
  _HttpResult(this.map, this.rawBody);

  final Map<String, dynamic> map;
  final String rawBody;
}
