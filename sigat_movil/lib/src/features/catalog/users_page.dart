import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _roles = const [
    {'id': 1, 'nombre': 'ADMIN'},
    {'id': 2, 'nombre': 'TRABAJADOR'},
  ];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final term = _searchController.text.toLowerCase().trim();
    if (term.isEmpty) return _users;
    return _users.where((user) {
      final haystack =
          '${user['nombre']} ${user['apellido']} ${user['email']} ${_roleName(user)}'
              .toLowerCase();
      return haystack.contains(term);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModuleHeader(
          eyebrow: 'Seguridad',
          title: 'Usuarios',
          trailing: IconButton.filled(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Agregar usuario',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Buscador',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        ErrorBanner(message: _error),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(
                        height: 220,
                        child: EmptyState(message: 'No hay usuarios'),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = _filtered[index];
                      return SigatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}'
                                        .trim(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                StatusChip(
                                  label: _roleName(user),
                                  color: _roleName(user) == 'ADMIN'
                                      ? AppTheme.blue
                                      : const Color(0xFF14804A),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(user['email']?.toString() ?? ''),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children: [
                                IconButton.filledTonal(
                                  onPressed: () => _openForm(user),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Editar',
                                ),
                                IconButton.filledTonal(
                                  onPressed: () => _confirmDelete(user),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final api = SessionScope.read(context).api;
    try {
      final roles = await api.list('/roles');
      if (roles.isNotEmpty) _roles = _prepareRoles(roles);
      _users = await api.list('/usuarios');
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? user]) async {
    final isEdit = user != null;
    final nombre = TextEditingController(
      text: user?['nombre']?.toString() ?? '',
    );
    final apellido = TextEditingController(
      text: user?['apellido']?.toString() ?? '',
    );
    final email = TextEditingController(text: user?['email']?.toString() ?? '');
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final firstRole = _roles.isNotEmpty
        ? _roles.first
        : const <String, dynamic>{};
    var roleId = _asInt(user?['rolId']) ?? _asInt(firstRole['id']) ?? 1;
    var saving = false;
    var formError = '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      isEdit ? 'Editar usuario' : 'Agregar usuario',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nombre,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: apellido,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (_required(value) != null) {
                          return _required(value);
                        }
                        return value!.contains('@') ? null : 'Correo no valido';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEdit
                            ? 'Nueva contrasena opcional'
                            : 'Contrasena',
                      ),
                      validator: (value) {
                        if (isEdit && (value == null || value.isEmpty)) {
                          return null;
                        }
                        if (value == null || value.length < 6) {
                          return 'Minimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: roleId,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: _roles.map((role) {
                        return DropdownMenuItem<int>(
                          value: _asInt(role['id']),
                          child: Text(_displayRole(role['nombre'])),
                        );
                      }).toList(),
                      onChanged: (value) => roleId = value ?? roleId,
                    ),
                    const SizedBox(height: 12),
                    ErrorBanner(message: formError),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              setSheetState(() {
                                saving = true;
                                formError = '';
                              });

                              try {
                                final emailValue = _normalizeEmail(email.text);
                                final currentId = isEdit
                                    ? _asInt(user['id'])
                                    : null;
                                final duplicated = _users.any((existing) {
                                  return _normalizeEmail(
                                            existing['email']?.toString() ?? '',
                                          ) ==
                                          emailValue &&
                                      _asInt(existing['id']) != currentId;
                                });

                                if (duplicated) {
                                  setSheetState(() {
                                    formError =
                                        'Ya existe un usuario con ese email';
                                    saving = false;
                                  });
                                  return;
                                }

                                final payload = <String, dynamic>{
                                  'nombre': nombre.text.trim(),
                                  'apellido': apellido.text.trim(),
                                  'email': emailValue,
                                  'rolId': roleId,
                                };
                                if (password.text.trim().isNotEmpty ||
                                    !isEdit) {
                                  payload['password'] = password.text.trim();
                                }

                                final api = SessionScope.read(context).api;
                                if (isEdit) {
                                  await api.put(
                                    '/usuarios/${user['id']}',
                                    payload,
                                  );
                                } else {
                                  await api.post('/usuarios', payload);
                                }
                                if (!mounted || !sheetContext.mounted) {
                                  return;
                                }
                                // Cierra primero; recarga y aviso despues de
                                // liberar los controladores (evita reconstruir
                                // un TextField con su controller ya liberado).
                                Navigator.pop(sheetContext, true);
                              } on ApiException catch (error) {
                                // No se llama a setSheetState tras cerrar el
                                // sheet: rearmaria los TextField con sus
                                // controladores ya en proceso de liberacion.
                                if (sheetContext.mounted) {
                                  setSheetState(() {
                                    formError = error.message;
                                    saving = false;
                                  });
                                }
                              }
                            },
                      child: Text(
                        saving
                            ? 'Guardando...'
                            : isEdit
                            ? 'Actualizar'
                            : 'Agregar',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.pop(sheetContext),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Se liberan los controladores tras la animacion de cierre de la hoja
    // modal, no al instante, para no reconstruir un TextField ya liberado.
    final pendientes = [nombre, apellido, email, password];
    Future.delayed(const Duration(milliseconds: 350), () {
      for (final controller in pendientes) {
        controller.dispose();
      }
    });

    if (saved == true && mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Usuario actualizado' : 'Usuario creado'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final api = SessionScope.read(context).api;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: Text('Deseas eliminar ${user['nombre'] ?? 'este usuario'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await api.delete('/usuarios/${user['id']}');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  List<Map<String, dynamic>> _prepareRoles(List<Map<String, dynamic>> roles) {
    final unique = <String, Map<String, dynamic>>{};
    for (final role in roles) {
      unique[_displayRole(role['nombre'])] = {
        ...role,
        'nombre': _displayRole(role['nombre']),
      };
    }
    final prepared = unique.values.toList();
    prepared.sort((a, b) {
      final aWeight = _displayRole(a['nombre']) == 'ADMIN' ? 0 : 1;
      final bWeight = _displayRole(b['nombre']) == 'ADMIN' ? 0 : 1;
      return aWeight.compareTo(bWeight);
    });
    return prepared;
  }

  String _roleName(Map<String, dynamic> user) =>
      _displayRole(user['rolNombre']);

  String _displayRole(Object? value) {
    final normalized = value?.toString().toUpperCase().trim() ?? '';
    return normalized.contains('ADMIN') ? 'ADMIN' : 'TRABAJADOR';
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo requerido' : null;
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
