import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';

typedef EntityLoader =
    Future<List<Map<String, dynamic>>> Function(ApiClient api);
typedef EntityWriter =
    Future<void> Function(ApiClient api, Map<String, dynamic> payload, int? id);
typedef EntityRemover = Future<void> Function(ApiClient api, int id);
typedef EntityLabel = String Function(Map<String, dynamic> item);
typedef EntityStatusBuilder = Widget? Function(Map<String, dynamic> item);

enum EntityFieldType { text, email, integer, decimal, multiline, password }

class EntityField {
  const EntityField({
    required this.key,
    required this.label,
    this.type = EntityFieldType.text,
    this.required = true,
    this.defaultValue = '',
  });

  final String key;
  final String label;
  final EntityFieldType type;
  final bool required;
  final Object defaultValue;
}

class EntityDetail {
  const EntityDetail(this.label, this.key, {this.formatter});

  final String label;
  final String key;
  final String Function(Object? value)? formatter;
}

class EntityDefinition {
  const EntityDefinition({
    required this.eyebrow,
    required this.title,
    required this.createLabel,
    required this.emptyLabel,
    required this.fields,
    required this.details,
    required this.searchKeys,
    required this.load,
    required this.create,
    required this.update,
    required this.remove,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.statusBuilder,
  });

  final String eyebrow;
  final String title;
  final String createLabel;
  final String emptyLabel;
  final List<EntityField> fields;
  final List<EntityDetail> details;
  final List<String> searchKeys;
  final EntityLoader load;
  final EntityWriter create;
  final EntityWriter update;
  final EntityRemover remove;
  final EntityLabel titleBuilder;
  final EntityLabel subtitleBuilder;
  final EntityStatusBuilder? statusBuilder;
}

class EntityListPage extends StatefulWidget {
  const EntityListPage({super.key, required this.definition});

  final EntityDefinition definition;

  @override
  State<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends State<EntityListPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
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
    if (term.isEmpty) return _items;
    return _items.where((item) {
      return widget.definition.searchKeys.any((key) {
        return (item[key]?.toString().toLowerCase() ?? '').contains(term);
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final definition = widget.definition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModuleHeader(
          eyebrow: definition.eyebrow,
          title: definition.title,
          trailing: IconButton.filled(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            tooltip: definition.createLabel,
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
                    children: [
                      SizedBox(
                        height: 220,
                        child: EmptyState(message: definition.emptyLabel),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _EntityCard(
                      item: _filtered[index],
                      definition: definition,
                      onView: () => _openDetail(_filtered[index]),
                      onEdit: () => _openForm(_filtered[index]),
                      onDelete: () => _confirmDelete(_filtered[index]),
                    ),
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
    try {
      final api = SessionScope.read(context).api;
      final items = await widget.definition.load(api);
      if (!mounted) return;
      setState(() => _items = items);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id == null) return;
    final api = SessionScope.read(context).api;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: Text(
          'Deseas eliminar ${widget.definition.titleBuilder(item)}?',
        ),
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
      await widget.definition.remove(api, id);
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final isEdit = item != null;
    final controllers = <String, TextEditingController>{
      for (final field in widget.definition.fields)
        field.key: TextEditingController(text: _fieldInitialValue(field, item)),
    };
    final formKey = GlobalKey<FormState>();
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
                      isEdit
                          ? 'Editar ${widget.definition.title}'
                          : widget.definition.createLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final field in widget.definition.fields) ...[
                      TextFormField(
                        controller: controllers[field.key],
                        keyboardType: _keyboardType(field.type),
                        obscureText: field.type == EntityFieldType.password,
                        minLines: field.type == EntityFieldType.multiline
                            ? 3
                            : 1,
                        maxLines: field.type == EntityFieldType.multiline
                            ? 5
                            : 1,
                        decoration: InputDecoration(labelText: field.label),
                        validator: (value) => _validateField(field, value),
                      ),
                      const SizedBox(height: 12),
                    ],
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
                                final payload = _payloadFromControllers(
                                  controllers,
                                );
                                final api = SessionScope.read(context).api;
                                if (isEdit) {
                                  await widget.definition.update(
                                    api,
                                    payload,
                                    _asInt(item['id']),
                                  );
                                } else {
                                  await widget.definition.create(
                                    api,
                                    payload,
                                    null,
                                  );
                                }
                                if (!mounted || !sheetContext.mounted) {
                                  return;
                                }
                                // Cierra el sheet devolviendo "guardado". La
                                // recarga de la lista se hace despues de cerrar
                                // y liberar los controladores, para no rearmar
                                // un TextField con su controller ya liberado.
                                Navigator.pop(sheetContext, true);
                              } on ApiException catch (error) {
                                // Solo se rearma el estado del sheet si sigue
                                // abierto (caso de error). Tras cerrarlo NO se
                                // llama a setSheetState: rearmaria los TextField
                                // cuyos controladores estan por liberarse.
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

    // La hoja modal sigue animando su cierre cuando este Future se completa
    // (showModalBottomSheet retorna al hacer pop, no al terminar la animacion).
    // Se liberan los controladores despues de esa animacion para no reconstruir
    // los TextField con un controlador ya liberado.
    _disposeAfterSheetClose(controllers.values);

    if (saved == true && mounted) {
      await _load();
    }
  }

  void _disposeAfterSheetClose(Iterable<TextEditingController> controllers) {
    final pendientes = controllers.toList();
    Future.delayed(const Duration(milliseconds: 350), () {
      for (final controller in pendientes) {
        controller.dispose();
      }
    });
  }

  void _openDetail(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Detalle ${widget.definition.title}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final detail in widget.definition.details)
                _DetailRow(
                  label: detail.label,
                  value:
                      detail.formatter?.call(item[detail.key]) ??
                      item[detail.key]?.toString() ??
                      '',
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fieldInitialValue(EntityField field, Map<String, dynamic>? item) {
    final value = item == null
        ? field.defaultValue
        : item[field.key] ?? field.defaultValue;
    return value.toString();
  }

  String? _validateField(EntityField field, String? value) {
    final text = value?.trim() ?? '';
    if (field.required && text.isEmpty) return 'Campo requerido';
    if (text.isEmpty) return null;
    if (field.type == EntityFieldType.email && !text.contains('@')) {
      return 'Correo no valido';
    }
    if ((field.type == EntityFieldType.decimal ||
            field.type == EntityFieldType.integer) &&
        num.tryParse(text) == null) {
      return 'Numero no valido';
    }
    return null;
  }

  Map<String, dynamic> _payloadFromControllers(
    Map<String, TextEditingController> controllers,
  ) {
    final payload = <String, dynamic>{};
    for (final field in widget.definition.fields) {
      final value = controllers[field.key]!.text.trim();
      if (field.type == EntityFieldType.integer) {
        payload[field.key] = int.tryParse(value) ?? 0;
      } else if (field.type == EntityFieldType.decimal) {
        payload[field.key] = double.tryParse(value) ?? 0.0;
      } else {
        payload[field.key] = value;
      }
    }
    return payload;
  }

  TextInputType _keyboardType(EntityFieldType type) {
    return switch (type) {
      EntityFieldType.email => TextInputType.emailAddress,
      EntityFieldType.integer => TextInputType.number,
      EntityFieldType.decimal => const TextInputType.numberWithOptions(
        decimal: true,
      ),
      EntityFieldType.multiline => TextInputType.multiline,
      EntityFieldType.password || EntityFieldType.text => TextInputType.text,
    };
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.item,
    required this.definition,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final EntityDefinition definition;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SigatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.titleBuilder(item),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.subtitleBuilder(item),
                      style: TextStyle(
                        color: AppTheme.ink.withValues(alpha: 0.64),
                      ),
                    ),
                  ],
                ),
              ),
              if (definition.statusBuilder != null)
                definition.statusBuilder!(item) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              IconButton.filledTonal(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
                tooltip: 'Ver',
              ),
              IconButton.filledTonal(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
              ),
              IconButton.filledTonal(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}
