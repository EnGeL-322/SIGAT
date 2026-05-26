import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';

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
    final id = item['id'];
    final future = SessionScope.read(
      context,
    ).api.list('${widget.type.detailPath}/$id/detalles');

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Detalle ${widget.type.singular}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return EmptyState(
                          message: snapshot.error.toString(),
                          icon: Icons.error_outline,
                        );
                      }
                      final details = snapshot.data ?? const [];
                      if (details.isEmpty) {
                        return const EmptyState(message: 'Sin detalles');
                      }
                      return ListView.separated(
                        itemCount: details.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final detail = details[index];
                          final imeis = detail['imeis'] is List
                              ? detail['imeis'] as List
                              : const [];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              detail['productoNombre']?.toString() ?? '',
                            ),
                            subtitle: Text(
                              'Cantidad: ${detail['cantidad'] ?? 1} - Precio: ${formatMoney(detail['precioUnitario'])}'
                              '${imeis.isEmpty ? '' : '\nIMEI: ${imeis.map((e) => e is Map ? e['numero'] : '').where((e) => e.toString().isNotEmpty).join(', ')}'}',
                            ),
                            trailing: Text(formatMoney(detail['subtotal'])),
                          );
                        },
                      );
                    },
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        );
      },
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
                    DropdownButtonFormField<int>(
                      initialValue: _partyId,
                      decoration: InputDecoration(labelText: type.partyLabel),
                      items: _parties.map((party) {
                        return DropdownMenuItem<int>(
                          value: _asInt(party['id']),
                          child: Text(_partyName(party)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _partyId = value),
                    ),
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
