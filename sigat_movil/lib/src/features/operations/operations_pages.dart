import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';
import '../catalog/entity_list_page.dart';

class PurchasesPage extends StatelessWidget {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const MovementListPage(type: MovementType.purchase);
}

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const MovementListPage(type: MovementType.sale);
}

class PurchaseFormPage extends StatelessWidget {
  const PurchaseFormPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const MovementFormPage(type: MovementType.purchase);
}

class SaleFormPage extends StatelessWidget {
  const SaleFormPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const MovementFormPage(type: MovementType.sale);
}

enum MovementType { purchase, sale }

extension MovementLabels on MovementType {
  bool get isPurchase => this == MovementType.purchase;
  String get title => isPurchase ? 'Compras' : 'Ventas';
  String get singular => isPurchase ? 'compra' : 'venta';
  String get listPath => isPurchase ? '/compras' : '/ventas';
  String get formRoute => isPurchase ? '/compras/nueva' : '/ventas/nueva';
  String get numberKey => isPurchase ? 'numeroCompra' : 'numeroVenta';
  String get partyKey => isPurchase ? 'proveedorNombre' : 'clienteNombre';
  String get dateKey => isPurchase ? 'fechaCompra' : 'fechaVenta';
  String get partyEndpoint => isPurchase ? '/proveedores' : '/clientes';
  String get partyIdKey => isPurchase ? 'proveedorId' : 'clienteId';
  String get partyLabel => isPurchase ? 'Proveedor' : 'Cliente';
  String get detailPath => isPurchase ? '/compras' : '/ventas';
  String get createPartyLabel => isPurchase ? 'Nuevo proveedor' : 'Nuevo cliente';
  String get addPartyLabel =>
      isPurchase ? 'Agregar datos del proveedor' : 'Agregar datos del cliente';

  /// Clave unica para localizar el registro recien creado tras recargar.
  String get partyMatchKey => isPurchase ? 'ruc' : 'cedula';

  /// Campos completos del proveedor/cliente para el alta rapida.
  List<EntityField> get partyFields => isPurchase
      ? const [
          EntityField(key: 'nombre', label: 'Nombre / Razon social'),
          EntityField(key: 'ruc', label: 'RUC'),
          EntityField(key: 'email', label: 'Email', type: EntityFieldType.email),
          EntityField(key: 'telefono', label: 'Telefono'),
          EntityField(key: 'contacto', label: 'Contacto', required: false),
          EntityField(
            key: 'direccion',
            label: 'Direccion',
            type: EntityFieldType.multiline,
            required: false,
          ),
        ]
      : const [
          EntityField(key: 'nombre', label: 'Nombre'),
          EntityField(key: 'apellido', label: 'Apellido'),
          EntityField(key: 'cedula', label: 'Cedula'),
          EntityField(key: 'email', label: 'Email', type: EntityFieldType.email),
          EntityField(key: 'telefono', label: 'Telefono'),
          EntityField(
            key: 'direccion',
            label: 'Direccion',
            type: EntityFieldType.multiline,
            required: false,
          ),
        ];
}

class MovementListPage extends StatefulWidget {
  const MovementListPage({super.key, required this.type});

  final MovementType type;

  @override
  State<MovementListPage> createState() => _MovementListPageState();
}

class _MovementListPageState extends State<MovementListPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModuleHeader(
          eyebrow: 'Operaciones',
          title: type.title,
          trailing: IconButton.filled(
            onPressed: () => Navigator.pushNamed(context, type.formRoute),
            icon: const Icon(Icons.add),
            tooltip: 'Nueva ${type.singular}',
          ),
        ),
        const SizedBox(height: 10),
        ErrorBanner(message: _error),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: 220,
                        child: EmptyState(
                          message: 'No hay ${type.title.toLowerCase()}',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return SigatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item[type.numberKey]?.toString() ??
                                        '${type.singular} ${item['id']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                StatusChip(
                                  label: item['estado']?.toString() ?? 'OK',
                                  color: AppTheme.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${type.partyLabel}: ${item[type.partyKey] ?? '-'}',
                            ),
                            Text('Fecha: ${formatDate(item[type.dateKey])}'),
                            Text('Total: ${formatMoney(item['total'])}'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              children: [
                                IconButton.filledTonal(
                                  onPressed: () => _showDetails(item),
                                  icon: const Icon(Icons.visibility_outlined),
                                  tooltip: 'Ver detalle',
                                ),
                                IconButton.filledTonal(
                                  onPressed: () => _confirmDelete(item),
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
    try {
      final items = await SessionScope.read(
        context,
      ).api.list(widget.type.listPath);
      if (mounted) setState(() => _items = items.reversed.toList());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDetails(Map<String, dynamic> item) async {
    final api = SessionScope.read(context).api;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) =>
          _MovementDetailSheet(type: widget.type, item: item, api: api),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final api = SessionScope.read(context).api;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar ${widget.type.singular}'),
        content: Text(
          'Deseas eliminar ${item[widget.type.numberKey] ?? 'este registro'}?',
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
      await api.delete('${widget.type.listPath}/${item['id']}');
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }
}

class MovementFormPage extends StatefulWidget {
  const MovementFormPage({super.key, required this.type});

  final MovementType type;

  @override
  State<MovementFormPage> createState() => _MovementFormPageState();
}

class _MovementFormPageState extends State<MovementFormPage> {
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  List<Map<String, dynamic>> _parties = [];
  List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _details = [];
  int? _partyId;
  int? _productId;
  bool _loading = true;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              ModuleHeader(
                eyebrow: 'Operaciones',
                title: 'Nueva ${type.singular}',
                trailing: IconButton.filledTonal(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, type.listPath),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver',
                ),
              ),
              const SizedBox(height: 12),
              ErrorBanner(message: _error),
              SigatCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _partyId,
                            decoration: InputDecoration(
                              labelText: type.partyLabel,
                            ),
                            items: _parties.map((party) {
                              return DropdownMenuItem<int>(
                                value: _asInt(party['id']),
                                child: Text(_partyName(party)),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _partyId = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _openNewParty,
                          icon: const Icon(Icons.person_add_alt_1),
                          tooltip: type.createPartyLabel,
                        ),
                      ],
                    ),
                    if (_parties.isEmpty) _partyEmptyHint(),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _productId,
                      decoration: const InputDecoration(labelText: 'Producto'),
                      items: _products.map((product) {
                        return DropdownMenuItem<int>(
                          value: _asInt(product['id']),
                          child: Text(
                            '${product['marca'] ?? ''} ${product['modelo'] ?? product['nombre'] ?? ''}'
                                .trim(),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        _productId = value;
                        final product = _selectedProduct;
                        if (product != null) {
                          _priceController.text = _asNum(
                            product['precio'],
                          ).toStringAsFixed(2);
                        }
                      }),
                    ),
                    if (_productId != null && _selectedProduct != null)
                      _stockBadge(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Precio unitario',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addDetail,
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text('Agregar detalle'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SigatCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Detalle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_details.isEmpty)
                      const Text('Sin productos agregados')
                    else
                      for (var i = 0; i < _details.length; i++)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _details[i]['productoNombre']?.toString() ?? '',
                          ),
                          subtitle: Text(
                            'Cantidad: ${_details[i]['cantidad']} - ${formatMoney(_details[i]['precioUnitario'])}',
                          ),
                          trailing: IconButton(
                            onPressed: () =>
                                setState(() => _details.removeAt(i)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                    const Divider(),
                    Text(
                      'Total: ${formatMoney(_total())}',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Guardando...' : 'Guardar ${type.singular}',
                ),
              ),
            ],
          );
  }

  Map<String, dynamic>? get _selectedProduct {
    return _products.cast<Map<String, dynamic>?>().firstWhere(
      (product) => _asInt(product?['id']) == _productId,
      orElse: () => null,
    );
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final api = SessionScope.read(context).api;
      final result = await Future.wait([
        api.list(widget.type.partyEndpoint),
        api.list('/productos'),
      ]);
      if (!mounted) return;
      setState(() {
        _parties = result[0];
        _products = result[1];
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Abre el formulario para registrar un proveedor/cliente con todos sus
  /// datos sin salir de la operacion. Al guardar, recarga la lista y deja
  /// seleccionado el registro recien creado.
  Future<void> _openNewParty() async {
    final type = widget.type;
    final fields = type.partyFields;
    final api = SessionScope.read(context).api;
    final controllers = <String, TextEditingController>{
      for (final field in fields)
        field.key: TextEditingController(text: field.defaultValue.toString()),
    };
    final formKey = GlobalKey<FormState>();
    var saving = false;
    var formError = '';

    final created = await showModalBottomSheet<Map<String, dynamic>>(
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
                      type.createPartyLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final field in fields) ...[
                      TextFormField(
                        controller: controllers[field.key],
                        keyboardType: _partyKeyboardType(field.type),
                        minLines: field.type == EntityFieldType.multiline
                            ? 3
                            : 1,
                        maxLines: field.type == EntityFieldType.multiline
                            ? 5
                            : 1,
                        decoration: InputDecoration(labelText: field.label),
                        validator: (value) => _validatePartyField(field, value),
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
                                final payload = <String, dynamic>{
                                  for (final field in fields)
                                    field.key: controllers[field.key]!.text
                                        .trim(),
                                };
                                final response = await api.post(
                                  type.partyEndpoint,
                                  payload,
                                );
                                final createdParty = ApiClient.mapFromResponse(
                                  response,
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.pop(
                                  sheetContext,
                                  createdParty.isEmpty ? payload : createdParty,
                                );
                              } on ApiException catch (error) {
                                setSheetState(() => formError = error.message);
                              } finally {
                                if (sheetContext.mounted) {
                                  setSheetState(() => saving = false);
                                }
                              }
                            },
                      child: Text(saving ? 'Guardando...' : 'Agregar'),
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

    for (final controller in controllers.values) {
      controller.dispose();
    }

    if (created != null && mounted) {
      await _reloadPartiesSelecting(created);
    }
  }

  /// Recarga proveedores/clientes y selecciona el creado por id o clave unica.
  Future<void> _reloadPartiesSelecting(Map<String, dynamic> created) async {
    final type = widget.type;
    final api = SessionScope.read(context).api;
    try {
      final parties = await api.list(type.partyEndpoint);
      if (!mounted) return;
      final createdId = _asInt(created['id']);
      final createdMatch = created[type.partyMatchKey]?.toString();
      Map<String, dynamic>? found;
      for (final party in parties) {
        if (createdId != null && _asInt(party['id']) == createdId) {
          found = party;
          break;
        }
        if (createdMatch != null &&
            createdMatch.isNotEmpty &&
            party[type.partyMatchKey]?.toString() == createdMatch) {
          found = party;
          break;
        }
      }
      setState(() {
        _parties = parties;
        if (found != null) _partyId = _asInt(found['id']);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  TextInputType _partyKeyboardType(EntityFieldType type) {
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

  String? _validatePartyField(EntityField field, String? value) {
    final text = value?.trim() ?? '';
    if (field.required && text.isEmpty) return 'Campo requerido';
    if (text.isEmpty) return null;
    if (field.type == EntityFieldType.email && !text.contains('@')) {
      return 'Correo no valido';
    }
    return null;
  }

  Widget _partyEmptyHint() {
    final type = widget.type;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.blue.withValues(alpha: 0.30),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                type.isPurchase
                    ? Icons.local_shipping_outlined
                    : Icons.person_outline,
                color: AppTheme.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.isPurchase
                      ? 'Aun no tienes proveedores registrados'
                      : 'Aun no tienes clientes registrados',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            type.isPurchase
                ? 'Para registrar una compra nueva primero agrega todos los datos del proveedor.'
                : 'Para registrar una venta nueva primero agrega todos los datos del cliente.',
            style: TextStyle(color: AppTheme.ink.withValues(alpha: 0.64)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openNewParty,
            icon: const Icon(Icons.add),
            label: Text(type.addPartyLabel),
          ),
        ],
      ),
    );
  }

  void _addDetail() {
    final product = _selectedProduct;
    final quantity = int.tryParse(_qtyController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    if (product == null || quantity <= 0 || price <= 0) {
      setState(() => _error = 'Selecciona producto, cantidad y precio validos');
      return;
    }

    if (!widget.type.isPurchase) {
      final stock = _asNum(product['stockActual']).toInt();
      if (quantity > stock) {
        setState(() => _error = 'Stock insuficiente. Disponible: $stock');
        return;
      }
    }

    setState(() {
      _error = '';
      _details.add({
        'productoId': _asInt(product['id']),
        'productoNombre':
            product['nombre'] ??
            '${product['marca'] ?? ''} ${product['modelo'] ?? ''}'.trim(),
        'cantidad': quantity,
        'precioUnitario': price,
      });
      _productId = null;
      _qtyController.text = '1';
      _priceController.clear();
    });
  }

  Future<void> _save() async {
    if (_partyId == null || _details.isEmpty) {
      setState(
        () => _error =
            'Selecciona ${widget.type.partyLabel.toLowerCase()} y agrega detalle',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    final payload = {
      widget.type.isPurchase ? 'compra' : 'venta': {
        widget.type.partyIdKey: _partyId,
      },
      'detalles': _details
          .map(
            (detail) => {
              'productoId': detail['productoId'],
              'cantidad': detail['cantidad'],
              'precioUnitario': detail['precioUnitario'],
            },
          )
          .toList(),
    };

    try {
      await SessionScope.read(context).api.post(widget.type.listPath, payload);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, widget.type.listPath);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _total() {
    return _details.fold(0, (sum, detail) {
      return sum +
          (_asNum(detail['cantidad']) * _asNum(detail['precioUnitario']));
    });
  }

  String _partyName(Map<String, dynamic> party) {
    if (widget.type.isPurchase) return party['nombre']?.toString() ?? '';
    return '${party['nombre'] ?? ''} ${party['apellido'] ?? ''}'.trim();
  }

  Widget _stockBadge() {
    final stock = _asNum(_selectedProduct?['stockActual']).toInt();
    final color = stock <= 0
        ? AppTheme.rose
        : (stock <= 5 ? const Color(0xFFB7791F) : const Color(0xFF14804A));
    final text = stock <= 0
        ? 'Sin stock disponible'
        : 'Quedan $stock dispositivo(s)';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja de detalle de una compra/venta con buscador por IMEI o producto.
class _MovementDetailSheet extends StatefulWidget {
  const _MovementDetailSheet({
    required this.type,
    required this.item,
    required this.api,
  });

  final MovementType type;
  final Map<String, dynamic> item;
  final ApiClient api;

  @override
  State<_MovementDetailSheet> createState() => _MovementDetailSheetState();
}

class _MovementDetailSheetState extends State<_MovementDetailSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _details = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final id = widget.item['id'];
      final details = await widget.api.list(
        '${widget.type.detailPath}/$id/detalles',
      );
      if (mounted) {
        setState(() {
          _details = details;
          _loading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _details;
    return _details.where((detail) {
      final producto = (detail['productoNombre']?.toString() ?? '')
          .toLowerCase();
      if (producto.contains(query)) return true;

      final imeiVenta = (detail['imeiNumero']?.toString() ?? '').toLowerCase();
      if (imeiVenta.contains(query)) return true;

      final imeis = detail['imeis'];
      if (imeis is List) {
        return imeis.any(
          (imei) =>
              imei is Map &&
              (imei['numero']?.toString() ?? '').toLowerCase().contains(query),
        );
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    final filtered = _filtered;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Detalle ${type.singular}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text('${type.partyLabel}: ${widget.item[type.partyKey] ?? '-'}'),
            Text('Total: ${formatMoney(widget.item['total'])}'),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por IMEI o producto',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? EmptyState(message: _error, icon: Icons.error_outline)
                  : filtered.isEmpty
                  ? const EmptyState(message: 'Sin resultados')
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final detail = filtered[index];
                        return type.isPurchase
                            ? _PurchaseDetailTile(
                                detail: detail,
                                search: _searchController.text.trim(),
                              )
                            : _SaleDetailTile(detail: detail);
                      },
                    ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de compra: muestra el producto y la lista de IMEIs generados.
class _PurchaseDetailTile extends StatelessWidget {
  const _PurchaseDetailTile({required this.detail, required this.search});

  final Map<String, dynamic> detail;
  final String search;

  @override
  Widget build(BuildContext context) {
    final imeis = detail['imeis'] is List
        ? (detail['imeis'] as List)
        : const [];
    final query = search.toLowerCase();
    final visibles = query.isEmpty
        ? imeis
        : imeis
              .where(
                (imei) =>
                    imei is Map &&
                    (imei['numero']?.toString() ?? '').toLowerCase().contains(
                      query,
                    ),
              )
              .toList();

    return SigatCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 6),
          initiallyExpanded: query.isNotEmpty,
          title: Text(detail['productoNombre']?.toString() ?? ''),
          subtitle: Text(
            'Cantidad: ${detail['cantidad'] ?? 0} - ${formatMoney(detail['precioUnitario'])}\n'
            'IMEIs: ${imeis.length}',
          ),
          trailing: const Icon(Icons.phone_android),
          children: [
            for (final imei in visibles)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.smartphone_outlined, size: 18),
                title: Text(imei is Map ? (imei['numero']?.toString() ?? '') : ''),
                trailing: StatusChip(
                  label: imei is Map
                      ? (imei['estado']?.toString() ?? 'EN_STOCK')
                      : 'EN_STOCK',
                  color: _imeiColor(imei is Map ? imei['estado']?.toString() : null),
                ),
              ),
            if (visibles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin IMEIs para este criterio'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Item de venta: muestra el producto y el IMEI vendido.
class _SaleDetailTile extends StatelessWidget {
  const _SaleDetailTile({required this.detail});

  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final imei = detail['imeiNumero']?.toString();
    return SigatCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.smartphone_outlined),
        title: Text(detail['productoNombre']?.toString() ?? ''),
        subtitle: Text(
          'IMEI: ${imei == null || imei.isEmpty ? 'Automatico' : imei}\n'
          'Cantidad: ${detail['cantidad'] ?? 1}',
        ),
        trailing: Text(
          formatMoney(detail['precioUnitario'] ?? detail['subtotal']),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

Color _imeiColor(String? estado) {
  switch (estado) {
    case 'VENDIDO':
      return const Color(0xFFB7791F);
    case 'DEFECTUOSO':
      return AppTheme.rose;
    default:
      return const Color(0xFF14804A);
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

num _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
