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
      final matchesProduct =
          _productId == null || _asInt(row['productoId']) == _productId;
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
                              row['productoNombre']?.toString() ?? '',
                            ),
                            subtitle: Text(
                              '${row['codigoVenta'] ?? ''} - ${formatDate(row['fechaVenta'])}\n'
                              '${row['clienteNombre'] ?? ''} - IMEI ${row['imeiNumero'] ?? '-'}',
                            ),
                            trailing: Text(
                              formatMoney(
                                row['precioUnitario'] ?? row['subtotal'],
                              ),
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
      final detailGroups = await Future.wait(
        sales.map((sale) async {
          final details = await api.list('/ventas/${sale['id']}/detalles');
          return details.map((detail) {
            return {
              ...detail,
              'ventaId': sale['id'],
              'codigoVenta': sale['numeroVenta'],
              'fechaVenta': sale['fechaVenta'],
              'clienteId': sale['clienteId'],
              'clienteNombre': sale['clienteNombre'],
            };
          }).toList();
        }),
      );
      if (!mounted) return;
      setState(() {
        _clients = result[1];
        _products = result[2];
        _rows = detailGroups.expand((rows) => rows).toList();
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
      'Codigo;Fecha;Cliente;Producto;IMEI;Precio',
      ...rows.map((row) {
        return [
          row['codigoVenta'] ?? '',
          formatDate(row['fechaVenta']),
          row['clienteNombre'] ?? '',
          row['productoNombre'] ?? '',
          row['imeiNumero'] ?? '',
          row['precioUnitario'] ?? row['subtotal'] ?? '',
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
      builder: (context) => Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Detalle de venta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _Line('Codigo', row['codigoVenta']),
            _Line('Fecha', formatDate(row['fechaVenta'])),
            _Line('Cliente', row['clienteNombre']),
            _Line('Producto', row['productoNombre']),
            _Line('IMEI', row['imeiNumero']),
            _Line('Precio', formatMoney(row['precioUnitario'])),
            const SizedBox(height: 12),
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
    final total = rows.fold<num>(
      0,
      (sum, row) => sum + _asNum(row['precioUnitario'] ?? row['subtotal']),
    );
    final sales = rows.map((row) => row['ventaId']).toSet().length;
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
              value: rows.length.toString(),
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
