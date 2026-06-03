import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final _dateController = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _rows = [];
  int? _clientId;
  int? _productId;
  String _period = 'DIA';
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    return _rows.where((row) {
      final matchesClient =
          _clientId == null || _asInt(row['clienteId']) == _clientId;
      final detalles = row['detalles'] is List
          ? row['detalles'] as List
          : const [];
      final matchesProduct =
          _productId == null ||
          detalles.any(
            (detail) =>
                detail is Map && _asInt(detail['productoId']) == _productId,
          );
      final matchesPeriod = _isInPeriod(row['fechaVenta']?.toString());
      return matchesClient && matchesProduct && matchesPeriod;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModuleHeader(
          eyebrow: 'Reportes',
          title: 'Reporte ventas',
          trailing: IconButton.filledTonal(
            onPressed: filtered.isEmpty ? null : () => _copyCsv(filtered),
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar CSV',
          ),
        ),
        const SizedBox(height: 12),
        ErrorBanner(message: _error),
        _ReportFilters(
          dateController: _dateController,
          period: _period,
          onPeriodChanged: (value) => setState(() => _period = value),
          clients: _clients,
          products: _products,
          clientId: _clientId,
          productId: _productId,
          onClientChanged: (value) => setState(() => _clientId = value),
          onProductChanged: (value) => setState(() => _productId = value),
          onDateChanged: () => setState(() {}),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(
                        height: 220,
                        child: EmptyState(message: 'Sin ventas'),
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      _SalesSummary(rows: filtered),
                      const SizedBox(height: 10),
                      for (final row in filtered) ...[
                        SigatCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              row['codigoVenta']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${formatDate(row['fechaVenta'])} - ${row['clienteNombre'] ?? ''}\n'
                              'Equipos: ${row['cantidadEquipos'] ?? 0}',
                            ),
                            trailing: Text(
                              formatMoney(row['total']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            onTap: () => _showRow(row),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
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
      final result = await Future.wait([
        api.list('/ventas'),
        api.list('/clientes'),
        api.list('/productos'),
      ]);
      final sales = result[0];
      final rows = await Future.wait(
        sales.map((sale) async {
          final details = await api.list('/ventas/${sale['id']}/detalles');
          final total =
              sale['total'] ??
              details.fold<num>(
                0,
                (sum, detail) =>
                    sum + _asNum(detail['subtotal'] ?? detail['precioUnitario']),
              );
          return <String, dynamic>{
            'id': sale['id'],
            'codigoVenta': sale['numeroVenta'],
            'fechaVenta': sale['fechaVenta'],
            'clienteId': sale['clienteId'],
            'clienteNombre': sale['clienteNombre'],
            'vendedorNombre': sale['vendedorNombre'] ?? 'SIGAT',
            'total': total,
            'detalles': details,
            'cantidadEquipos': details.length,
          };
        }),
      );
      if (!mounted) return;
      setState(() {
        _clients = result[1];
        _products = result[2];
        _rows = rows;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isInPeriod(String? value) {
    if (_dateController.text.trim().isEmpty || value == null) return true;
    final base = DateTime.tryParse('${_dateController.text.trim()}T00:00:00');
    final target = DateTime.tryParse(value);
    if (base == null || target == null) return false;

    if (_period == 'DIA') {
      return target.year == base.year &&
          target.month == base.month &&
          target.day == base.day;
    }

    if (_period == 'SEMANA') {
      final start = base.subtract(Duration(days: base.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return target.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          target.isBefore(end);
    }

    return target.year == base.year && target.month == base.month;
  }

  Future<void> _copyCsv(List<Map<String, dynamic>> rows) async {
    final csv = [
      'Codigo;Fecha;Cliente;Equipos;Total;IMEIs',
      ...rows.map((row) {
        final detalles = row['detalles'] is List
            ? row['detalles'] as List
            : const [];
        final imeis = detalles
            .map((detail) => detail is Map ? detail['imeiNumero'] : null)
            .where((imei) => imei != null && imei.toString().isNotEmpty)
            .join(',');
        return [
          row['codigoVenta'] ?? '',
          formatDate(row['fechaVenta']),
          row['clienteNombre'] ?? '',
          row['cantidadEquipos'] ?? 0,
          row['total'] ?? '',
          imeis,
        ].join(';');
      }),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV copiado')));
  }

  void _showRow(Map<String, dynamic> row) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _SaleReportDetailSheet(row: row),
    );
  }
}

class PurchasesReportPage extends StatefulWidget {
  const PurchasesReportPage({super.key});

  @override
  State<PurchasesReportPage> createState() => _PurchasesReportPageState();
}

class _PurchasesReportPageState extends State<PurchasesReportPage> {
  final _dateController = TextEditingController();
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _rows = [];
  int? _providerId;
  int? _productId;
  String _period = 'DIA';
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    return _rows.where((row) {
      final matchesProvider =
          _providerId == null || _asInt(row['proveedorId']) == _providerId;
      final detalles = row['detalles'] is List
          ? row['detalles'] as List
          : const [];
      final matchesProduct =
          _productId == null ||
          detalles.any(
            (detail) =>
                detail is Map && _asInt(detail['productoId']) == _productId,
          );
      final matchesPeriod = _isInPeriod(row['fechaCompra']?.toString());
      return matchesProvider && matchesProduct && matchesPeriod;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModuleHeader(
          eyebrow: 'Reportes',
          title: 'Reporte compras',
          trailing: IconButton.filledTonal(
            onPressed: filtered.isEmpty ? null : () => _copyCsv(filtered),
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar CSV',
          ),
        ),
        const SizedBox(height: 12),
        ErrorBanner(message: _error),
        _PurchaseReportFilters(
          dateController: _dateController,
          period: _period,
          onPeriodChanged: (value) => setState(() => _period = value),
          providers: _providers,
          products: _products,
          providerId: _providerId,
          productId: _productId,
          onProviderChanged: (value) => setState(() => _providerId = value),
          onProductChanged: (value) => setState(() => _productId = value),
          onDateChanged: () => setState(() {}),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(
                        height: 220,
                        child: EmptyState(message: 'Sin compras'),
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      _PurchasesSummary(rows: filtered),
                      const SizedBox(height: 10),
                      for (final row in filtered) ...[
                        SigatCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              row['codigoCompra']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${formatDate(row['fechaCompra'])} - ${row['proveedorNombre'] ?? ''}\n'
                              'Equipos: ${row['cantidadEquipos'] ?? 0}',
                            ),
                            trailing: Text(
                              formatMoney(row['total']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            onTap: () => _showRow(row),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
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
      final result = await Future.wait([
        api.list('/compras'),
        api.list('/proveedores'),
        api.list('/productos'),
      ]);
      final purchases = result[0];
      final rows = await Future.wait(
        purchases.map((purchase) async {
          final details = await api.list('/compras/${purchase['id']}/detalles');
          final total =
              purchase['total'] ??
              details.fold<num>(
                0,
                (sum, detail) => sum + _asNum(detail['subtotal']),
              );
          final equipos = details.fold<num>(
            0,
            (sum, detail) => sum + _asNum(detail['cantidad']),
          );
          final imeis = details.fold<int>(0, (sum, detail) {
            final list = detail['imeis'];
            return sum + (list is List ? list.length : 0);
          });
          return <String, dynamic>{
            'id': purchase['id'],
            'codigoCompra': purchase['numeroCompra'],
            'fechaCompra': purchase['fechaCompra'],
            'proveedorId': purchase['proveedorId'],
            'proveedorNombre': purchase['proveedorNombre'],
            'total': total,
            'detalles': details,
            'cantidadEquipos': equipos.toInt(),
            'totalImeis': imeis,
          };
        }),
      );
      if (!mounted) return;
      setState(() {
        _providers = result[1];
        _products = result[2];
        _rows = rows;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isInPeriod(String? value) {
    if (_dateController.text.trim().isEmpty || value == null) return true;
    final base = DateTime.tryParse('${_dateController.text.trim()}T00:00:00');
    final target = DateTime.tryParse(value);
    if (base == null || target == null) return false;

    if (_period == 'DIA') {
      return target.year == base.year &&
          target.month == base.month &&
          target.day == base.day;
    }

    if (_period == 'SEMANA') {
      final start = base.subtract(Duration(days: base.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return target.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          target.isBefore(end);
    }

    return target.year == base.year && target.month == base.month;
  }

  Future<void> _copyCsv(List<Map<String, dynamic>> rows) async {
    final csv = [
      'Codigo;Fecha;Proveedor;Equipos;Total;IMEIs',
      ...rows.map((row) {
        final detalles = row['detalles'] is List
            ? row['detalles'] as List
            : const [];
        final imeis = detalles
            .expand(
              (detail) => detail is Map && detail['imeis'] is List
                  ? (detail['imeis'] as List)
                  : const [],
            )
            .map((imei) => imei is Map ? imei['numero'] : null)
            .where((numero) => numero != null)
            .join(',');
        return [
          row['codigoCompra'] ?? '',
          formatDate(row['fechaCompra']),
          row['proveedorNombre'] ?? '',
          row['cantidadEquipos'] ?? 0,
          row['total'] ?? '',
          imeis,
        ].join(';');
      }),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV copiado')));
  }

  void _showRow(Map<String, dynamic> row) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _PurchaseReportDetailSheet(row: row),
    );
  }
}

class LowStockReportPage extends StatefulWidget {
  const LowStockReportPage({super.key});

  @override
  State<LowStockReportPage> createState() => _LowStockReportPageState();
}

class _LowStockReportPageState extends State<LowStockReportPage> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  String _status = 'TODOS';
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
    return _products.where((item) {
      final status = _stockStatus(item);
      return (brand.isEmpty ||
              (item['marca']?.toString().toLowerCase() ?? '').contains(
                brand,
              )) &&
          (model.isEmpty ||
              (item['modelo']?.toString().toLowerCase() ?? '').contains(
                model,
              )) &&
          (_status == 'TODOS' || status == _status);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModuleHeader(
          eyebrow: 'Reportes',
          title: 'Bajo stock',
          trailing: IconButton.filledTonal(
            onPressed: filtered.isEmpty ? null : () => _copyCsv(filtered),
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copiar CSV',
          ),
        ),
        const SizedBox(height: 12),
        ErrorBanner(message: _error),
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
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: const [
            DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
            DropdownMenuItem(
              value: 'STOCK AGOTADO',
              child: Text('Stock agotado'),
            ),
            DropdownMenuItem(
              value: 'STOCK MINIMO',
              child: Text('Stock minimo'),
            ),
            DropdownMenuItem(value: 'STOCK BAJO', child: Text('Stock bajo')),
          ],
          onChanged: (value) => setState(() => _status = value ?? 'TODOS'),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(
                        height: 220,
                        child: EmptyState(
                          message: 'Sin productos en bajo stock',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final status = _stockStatus(item);
                      return SigatCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${item['marca'] ?? ''} ${item['modelo'] ?? ''}'
                                .trim(),
                          ),
                          subtitle: Text(
                            'Codigo: ${item['codigo'] ?? '-'}\nStock: ${item['stockActual'] ?? 0} / minimo ${item['stockMinimo'] ?? 0}',
                          ),
                          trailing: StatusChip(
                            label: status,
                            color: _stockColor(status),
                          ),
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
      if (!mounted) return;
      setState(() {
        _products = products
            .where(
              (item) =>
                  _asNum(item['stockActual']) <= _asNum(item['stockMinimo']),
            )
            .toList();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyCsv(List<Map<String, dynamic>> rows) async {
    final csv = [
      'Marca;Modelo;Codigo;Stock actual;Stock minimo;Estado',
      ...rows.map((item) {
        return [
          item['marca'] ?? '',
          item['modelo'] ?? '',
          item['codigo'] ?? '',
          item['stockActual'] ?? '',
          item['stockMinimo'] ?? '',
          _stockStatus(item),
        ].join(';');
      }),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV copiado')));
  }

  String _stockStatus(Map<String, dynamic> item) {
    final stock = _asNum(item['stockActual']);
    if (stock <= 0) {
      return 'STOCK AGOTADO';
    }
    if (stock <= 2) {
      return 'STOCK MINIMO';
    }
    return 'STOCK BAJO';
  }

  Color _stockColor(String status) {
    if (status == 'STOCK AGOTADO') {
      return AppTheme.rose;
    }
    if (status == 'STOCK MINIMO') {
      return const Color(0xFFB7791F);
    }
    return const Color(0xFF14804A);
  }
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.dateController,
    required this.period,
    required this.onPeriodChanged,
    required this.clients,
    required this.products,
    required this.clientId,
    required this.productId,
    required this.onClientChanged,
    required this.onProductChanged,
    required this.onDateChanged,
  });

  final TextEditingController dateController;
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final List<Map<String, dynamic>> clients;
  final List<Map<String, dynamic>> products;
  final int? clientId;
  final int? productId;
  final ValueChanged<int?> onClientChanged;
  final ValueChanged<int?> onProductChanged;
  final VoidCallback onDateChanged;

  @override
  Widget build(BuildContext context) {
    return SigatCard(
      child: Column(
        children: [
          TextField(
            controller: dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Fecha',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: DateTime.now(),
              );
              if (selected == null) return;
              dateController.text =
                  '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
              onDateChanged();
            },
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'DIA', label: Text('Dia')),
              ButtonSegment(value: 'SEMANA', label: Text('Semana')),
              ButtonSegment(value: 'MES', label: Text('Mes')),
            ],
            selected: {period},
            onSelectionChanged: (value) => onPeriodChanged(value.first),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: clientId,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...clients.map((client) {
                return DropdownMenuItem<int?>(
                  value: _asInt(client['id']),
                  child: Text(
                    '${client['nombre'] ?? ''} ${client['apellido'] ?? ''}'
                        .trim(),
                  ),
                );
              }),
            ],
            onChanged: onClientChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: productId,
            decoration: const InputDecoration(labelText: 'Producto'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...products.map((product) {
                return DropdownMenuItem<int?>(
                  value: _asInt(product['id']),
                  child: Text(
                    '${product['marca'] ?? ''} ${product['modelo'] ?? product['nombre'] ?? ''}'
                        .trim(),
                  ),
                );
              }),
            ],
            onChanged: onProductChanged,
          ),
        ],
      ),
    );
  }
}

class _SalesSummary extends StatelessWidget {
  const _SalesSummary({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<num>(0, (sum, row) => sum + _asNum(row['total']));
    final equipos = rows.fold<num>(
      0,
      (sum, row) => sum + _asNum(row['cantidadEquipos']),
    );
    final sales = rows.length;
    return SigatCard(
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total',
              value: formatMoney(total),
              icon: Icons.payments_outlined,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Equipos',
              value: equipos.toInt().toString(),
              icon: Icons.phone_android,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Ventas',
              value: sales.toString(),
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.blue),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Detalle de una venta del reporte con buscador por IMEI o producto.
class _SaleReportDetailSheet extends StatefulWidget {
  const _SaleReportDetailSheet({required this.row});

  final Map<String, dynamic> row;

  @override
  State<_SaleReportDetailSheet> createState() => _SaleReportDetailSheetState();
}

class _SaleReportDetailSheetState extends State<_SaleReportDetailSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _equipos {
    final detalles = widget.row['detalles'] is List
        ? widget.row['detalles'] as List
        : const [];
    final all = detalles
        .whereType<Map>()
        .map((detail) => Map<String, dynamic>.from(detail))
        .toList();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((detail) {
      final imei = (detail['imeiNumero']?.toString() ?? '').toLowerCase();
      final producto = (detail['productoNombre']?.toString() ?? '')
          .toLowerCase();
      return imei.contains(query) || producto.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final equipos = _equipos;
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
              'Detalle de venta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _Line('Codigo', row['codigoVenta']),
            _Line('Cliente', row['clienteNombre']),
            _Line('Vendedor', row['vendedorNombre']),
            _Line('Total', formatMoney(row['total'])),
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
              child: equipos.isEmpty
                  ? const EmptyState(message: 'Sin resultados')
                  : ListView.separated(
                      itemCount: equipos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final equipo = equipos[index];
                        final imei = equipo['imeiNumero']?.toString();
                        return SigatCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.smartphone_outlined),
                            title: Text(
                              equipo['productoNombre']?.toString() ?? '',
                            ),
                            subtitle: Text(
                              'IMEI: ${imei == null || imei.isEmpty ? 'Automatico' : imei}',
                            ),
                            trailing: Text(
                              formatMoney(
                                equipo['precioUnitario'] ?? equipo['subtotal'],
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        );
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

class _PurchaseReportFilters extends StatelessWidget {
  const _PurchaseReportFilters({
    required this.dateController,
    required this.period,
    required this.onPeriodChanged,
    required this.providers,
    required this.products,
    required this.providerId,
    required this.productId,
    required this.onProviderChanged,
    required this.onProductChanged,
    required this.onDateChanged,
  });

  final TextEditingController dateController;
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final List<Map<String, dynamic>> providers;
  final List<Map<String, dynamic>> products;
  final int? providerId;
  final int? productId;
  final ValueChanged<int?> onProviderChanged;
  final ValueChanged<int?> onProductChanged;
  final VoidCallback onDateChanged;

  @override
  Widget build(BuildContext context) {
    return SigatCard(
      child: Column(
        children: [
          TextField(
            controller: dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Fecha',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: DateTime.now(),
              );
              if (selected == null) return;
              dateController.text =
                  '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
              onDateChanged();
            },
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'DIA', label: Text('Dia')),
              ButtonSegment(value: 'SEMANA', label: Text('Semana')),
              ButtonSegment(value: 'MES', label: Text('Mes')),
            ],
            selected: {period},
            onSelectionChanged: (value) => onPeriodChanged(value.first),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: providerId,
            decoration: const InputDecoration(labelText: 'Proveedor'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...providers.map((provider) {
                return DropdownMenuItem<int?>(
                  value: _asInt(provider['id']),
                  child: Text(provider['nombre']?.toString() ?? ''),
                );
              }),
            ],
            onChanged: onProviderChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            initialValue: productId,
            decoration: const InputDecoration(labelText: 'Producto'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...products.map((product) {
                return DropdownMenuItem<int?>(
                  value: _asInt(product['id']),
                  child: Text(
                    '${product['marca'] ?? ''} ${product['modelo'] ?? product['nombre'] ?? ''}'
                        .trim(),
                  ),
                );
              }),
            ],
            onChanged: onProductChanged,
          ),
        ],
      ),
    );
  }
}

class _PurchasesSummary extends StatelessWidget {
  const _PurchasesSummary({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<num>(0, (sum, row) => sum + _asNum(row['total']));
    final equipos = rows.fold<num>(
      0,
      (sum, row) => sum + _asNum(row['cantidadEquipos']),
    );
    final imeis = rows.fold<num>(
      0,
      (sum, row) => sum + _asNum(row['totalImeis']),
    );
    return SigatCard(
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total',
              value: formatMoney(total),
              icon: Icons.payments_outlined,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Equipos',
              value: equipos.toInt().toString(),
              icon: Icons.phone_android,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Compras',
              value: rows.length.toString(),
              icon: Icons.shopping_bag_outlined,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'IMEIs',
              value: imeis.toInt().toString(),
              icon: Icons.qr_code_2_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detalle de una compra del reporte: equipos (IMEIs) con buscador.
class _PurchaseReportDetailSheet extends StatefulWidget {
  const _PurchaseReportDetailSheet({required this.row});

  final Map<String, dynamic> row;

  @override
  State<_PurchaseReportDetailSheet> createState() =>
      _PurchaseReportDetailSheetState();
}

class _PurchaseReportDetailSheetState
    extends State<_PurchaseReportDetailSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _equipos {
    final detalles = widget.row['detalles'] is List
        ? widget.row['detalles'] as List
        : const [];
    final equipos = <Map<String, dynamic>>[];
    for (final detalle in detalles) {
      if (detalle is! Map) continue;
      final imeis = detalle['imeis'];
      if (imeis is! List) continue;
      for (final imei in imeis) {
        if (imei is! Map) continue;
        equipos.add({
          'productoNombre': detalle['productoNombre'],
          'numero': imei['numero'],
          'estado': imei['estado'],
          'precioUnitario': detalle['precioUnitario'],
        });
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return equipos;
    return equipos.where((equipo) {
      final numero = (equipo['numero']?.toString() ?? '').toLowerCase();
      final producto = (equipo['productoNombre']?.toString() ?? '')
          .toLowerCase();
      return numero.contains(query) || producto.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final equipos = _equipos;
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
              'Detalle de compra',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _Line('Codigo', row['codigoCompra']),
            _Line('Proveedor', row['proveedorNombre']),
            _Line('Total', formatMoney(row['total'])),
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
              child: equipos.isEmpty
                  ? const EmptyState(message: 'Sin resultados')
                  : ListView.separated(
                      itemCount: equipos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final equipo = equipos[index];
                        return SigatCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.smartphone_outlined),
                            title: Text(
                              equipo['numero']?.toString() ?? '',
                            ),
                            subtitle: Text(
                              equipo['productoNombre']?.toString() ?? '',
                            ),
                            trailing: StatusChip(
                              label: equipo['estado']?.toString() ?? 'EN_STOCK',
                              color: _imeiColor(equipo['estado']?.toString()),
                            ),
                          ),
                        );
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

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(child: Text(value?.toString() ?? '-')),
        ],
      ),
    );
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
