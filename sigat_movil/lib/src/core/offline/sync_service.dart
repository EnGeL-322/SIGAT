import 'dart:async';

import 'package:flutter/material.dart';

import '../network/api_client.dart';
import 'offline_store.dart';

/// Vacia la cola de escrituras (outbox) cuando vuelve la conexion y expone
/// el estado offline / cantidad de cambios pendientes para la interfaz.
class SyncService extends ChangeNotifier {
  SyncService(this._api, this._store);

  final ApiClient _api;
  final OfflineStore _store;

  bool _offline = false;
  bool _syncing = false;
  int _pending = 0;

  bool get isOffline => _offline;
  bool get isSyncing => _syncing;
  int get pendingCount => _pending;

  /// Marca el estado de conexion conocido (lo alimenta el ApiClient).
  void markOnline() {
    if (_offline) {
      _offline = false;
      notifyListeners();
    }
  }

  void markOffline() {
    if (!_offline) {
      _offline = true;
      notifyListeners();
    }
  }

  Future<void> refreshPendingCount() async {
    final count = await _store.pendingCount();
    if (count != _pending) {
      _pending = count;
      notifyListeners();
    }
  }

  /// Reintenta cada escritura pendiente contra el backend. Se detiene si
  /// vuelve a perderse la conexion; si el servidor rechaza una (4xx, p. ej.
  /// stock agotado) la marca con error pero continua con las demas.
  Future<void> flush() async {
    if (_syncing) return;
    final pending = await _store.pending();
    if (pending.isEmpty) {
      await refreshPendingCount();
      return;
    }

    _syncing = true;
    notifyListeners();

    try {
      for (final entry in pending) {
        try {
          final response = await _api.sendRaw(
            entry.method,
            entry.path,
            body: entry.payload,
          );
          final serverId = _serverIdFromResponse(response);
          await _store.markSynced(entry.id, serverId: serverId);
          _offline = false;
        } on ApiException catch (error) {
          if (error.statusCode == null) {
            // Sin conexion: deja el resto en cola para mas tarde.
            _offline = true;
            break;
          }
          // El servidor rechazo la operacion: la deja registrada con su error.
          await _store.markError(entry.id, error.message);
        }
      }
      await _store.clearSynced();
    } finally {
      _syncing = false;
      await refreshPendingCount();
      notifyListeners();
    }
  }

  int? _serverIdFromResponse(Map<String, dynamic> response) {
    final data = response['datos'] ?? response['data'];
    if (data is Map) {
      final id = data['id'];
      if (id is int) return id;
      return int.tryParse('$id');
    }
    return null;
  }
}

/// Hace accesible el [SyncService] a cualquier widget del arbol.
class SyncScope extends InheritedNotifier<SyncService> {
  const SyncScope({
    super.key,
    required SyncService controller,
    required super.child,
  }) : super(notifier: controller);

  static SyncService? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SyncScope>()
        ?.notifier;
  }
}
