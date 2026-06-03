import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _brandController.addListener(() => setState(() {}));
    _modelController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final brand = _brandController.text.toLowerCase().trim();
    final model = _modelController.text.toLowerCase().trim();
    return _products.where((product) {
      final productBrand = product['marca']?.toString().toLowerCase() ?? '';
      final productModel = product['modelo']?.toString().toLowerCase() ?? '';
      return productBrand.contains(brand) && productModel.contains(model);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModuleHeader(
          eyebrow: 'Inventario',
          title: 'Stock general',
          trailing: IconButton.filledTonal(
            onPressed: _showSoldImeis,
            icon: const Icon(Icons.sell_outlined),
            tooltip: 'IMEI vendidos',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _brandController,
                decoration: const InputDecoration(hintText: 'Marca'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _modelController,
                decoration: const InputDecoration(hintText: 'Modelo'),
              ),
            ),
          ],
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
                        child: EmptyState(message: 'No hay stock'),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = _filtered[index];
                      final stock = _asNum(product['stockActual']).toInt();
                      return SigatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${product['marca'] ?? ''} ${product['modelo'] ?? ''}'
                                        .trim(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                _stockChip(stock),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Codigo: ${product['codigo'] ?? '-'}'),
                            Text('Stock actual: $stock'),
                            Text(
                              'Stock minimo: ${product['stockMinimo'] ?? 0}',
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => _showImeis(product),
                              icon: const Icon(Icons.qr_code_2_outlined),
                              label: const Text('Ver IMEI'),
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
      final products = await SessionScope.read(context).api.list('/productos');
      if (mounted) setState(() => _products = products);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showImeis(Map<String, dynamic> product) async {
    List<Map<String, dynamic>> imeis = [];
    var loading = true;
    var error = '';

    unawaitedFuture(() async {
      try {
        imeis = await SessionScope.read(
          context,
        ).api.list('/imei/producto/${product['id']}');
      } on ApiException catch (apiError) {
        error = apiError.message;
      } finally {
        loading = false;
      }
    });

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (loading) {
              Future<void>.delayed(const Duration(milliseconds: 150), () {
                if (context.mounted) setSheetState(() {});
              });
            }

            return Padding(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'IMEI ${product['modelo'] ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ErrorBanner(message: error),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : imeis.isEmpty
                          ? const EmptyState(message: 'Sin IMEI registrados')
                          : ListView.separated(
                              itemCount: imeis.length,
                              separatorBuilder: (_, _) => const Divider(),
                              itemBuilder: (context, index) {
                                final imei = imeis[index];
                                return ListTile(
                                  leading: const Icon(Icons.qr_code_2),
                                  title: Text(imei['numero']?.toString() ?? ''),
                                  subtitle: Text(
                                    [
                                      imei['estado']?.toString() ?? '',
                                      if (imei['numeroVenta'] != null)
                                        'Venta: ${imei['numeroVenta']}',
                                      if (imei['clienteNombre'] != null)
                                        'Cliente: ${imei['clienteNombre']}',
                                    ].join('\n'),
                                  ),
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
      },
    );
  }

  Future<void> _showSoldImeis() async {
    final future = SessionScope.read(context).api.list('/imei/vendidos');

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
                  'IMEI vendidos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
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
                      final imeis = snapshot.data ?? const [];
                      if (imeis.isEmpty) {
                        return const EmptyState(
                          message: 'Aun no hay telefonos vendidos',
                        );
                      }
                      return ListView.separated(
                        itemCount: imeis.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final imei = imeis[index];
                          return ListTile(
                            leading: const Icon(Icons.qr_code_2),
                            title: Text(imei['numero']?.toString() ?? ''),
                            subtitle: Text(
                              [
                                'Equipo: ${imei['productoNombre'] ?? '-'}',
                                'Venta: ${imei['numeroVenta'] ?? '-'}',
                                'Cliente: ${imei['clienteNombre'] ?? '-'}',
                              ].join('\n'),
                            ),
                            trailing: const StatusChip(
                              label: 'VENDIDO',
                              color: AppTheme.rose,
                            ),
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

  Widget _stockChip(int stock) {
    if (stock <= 0) {
      return const StatusChip(label: 'AGOTADO', color: AppTheme.rose);
    }
    if (stock <= 5) {
      return const StatusChip(label: 'STOCK BAJO', color: Color(0xFFB7791F));
    }
    return const StatusChip(label: 'DISPONIBLE', color: Color(0xFF14804A));
  }
}

num _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

void unawaitedFuture(Future<void> Function() action) {
  action();
}
