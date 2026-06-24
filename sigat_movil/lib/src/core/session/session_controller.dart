import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';

class AuthUser {
  const AuthUser({
    required this.token,
    required this.nombre,
    required this.email,
    required this.rol,
    this.usuarioId,
  });

  final String token;
  final int? usuarioId;
  final String nombre;
  final String email;
  final String rol;

  factory AuthUser.fromMap(Map<String, dynamic> data) {
    return AuthUser(
      token: data['token']?.toString() ?? '',
      usuarioId: _asInt(data['usuarioId'] ?? data['id']),
      nombre: data['nombre']?.toString() ?? 'Usuario',
      email: data['email']?.toString() ?? '',
      rol: data['rol']?.toString() ?? data['rolNombre']?.toString() ?? '',
    );
  }

  bool get isAdmin => normalizedRole.contains('ADMIN');

  String get roleLabel => isAdmin ? 'ADMIN' : 'TRABAJADOR';

  String get normalizedRole {
    return rol.toUpperCase().trim();
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class SessionController extends ChangeNotifier {
  SessionController(this.api);

  final ApiClient api;
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'sigat_session';

  AuthUser? _user;
  bool _busy = false;
  bool _restoring = true;
  String? _error;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null && _user!.token.isNotEmpty;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isBusy => _busy;
  bool get isRestoring => _restoring;
  String? get error => _error;

  /// Intenta recuperar una sesion guardada (p. ej. al reabrir la app).
  Future<void> restoreSession() async {
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw != null) {
        _setUser(AuthUser.fromMap(jsonDecode(raw) as Map<String, dynamic>));
      }
    } catch (_) {
      await _storage.delete(key: _sessionKey);
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      final response = await api.login(email, password);
      if (ApiClient.isSuccess(response)) {
        _setUser(AuthUser.fromMap(ApiClient.mapFromResponse(response)));
        return true;
      }
      _error =
          ApiClient.messageFromResponse(response) ?? 'Credenciales invalidas';
      return false;
    });
  }

  Future<bool> register(Map<String, dynamic> payload) async {
    return _run(() async {
      final response = await api.register(payload);
      if (ApiClient.isSuccess(response)) return true;
      _error =
          ApiClient.messageFromResponse(response) ?? 'No se pudo registrar';
      return false;
    });
  }

  Future<bool> requestPasswordReset(String email) async {
    return _run(() async {
      final response = await api.requestPasswordReset(email);
      if (ApiClient.isSuccess(response)) return true;
      _error =
          ApiClient.messageFromResponse(response) ??
          'No se pudo enviar el codigo';
      return false;
    });
  }

  Future<bool> resetPassword(Map<String, dynamic> payload) async {
    return _run(() async {
      final response = await api.resetPassword(payload);
      if (ApiClient.isSuccess(response)) return true;
      _error =
          ApiClient.messageFromResponse(response) ??
          'No se pudo actualizar la contrasena';
      return false;
    });
  }

  void logout() {
    _user = null;
    api.authToken = null;
    notifyListeners();
    unawaited(_storage.delete(key: _sessionKey));
  }

  Future<bool> _run(Future<bool> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      return await action();
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'Ocurrio un error inesperado';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _setUser(AuthUser user) {
    _user = user;
    api.authToken = user.token;
    unawaited(_storage.write(
      key: _sessionKey,
      value: jsonEncode({
        'token': user.token,
        'usuarioId': user.usuarioId,
        'nombre': user.nombre,
        'email': user.email,
        'rol': user.rol,
      }),
    ));
  }
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope no esta disponible');
    return scope!.notifier!;
  }

  static SessionController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<SessionScope>();
    final scope = element?.widget as SessionScope?;
    assert(scope != null, 'SessionScope no esta disponible');
    return scope!.notifier!;
  }
}
