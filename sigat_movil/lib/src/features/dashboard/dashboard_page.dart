import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/session/session_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _stats = <String, int>{
    'productos': 0,
    'proveedores': 0,
    'clientes': 0,
    'ventas': 0,
  };
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.watch(context);
    final isAdmin = session.isAdmin;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(
              label: isAdmin ? 'VISTA ADMIN' : 'VISTA TRABAJADOR',
              color: isAdmin ? AppTheme.blue : const Color(0xFF14804A),
            ),
          ),
          const SizedBox(height: 14),
          SigatCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Panel SIGAT Admin' : 'Panel SIGAT Trabajador',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? 'Hola ${session.user?.nombre ?? 'Usuario'}. Controla operaciones, maestros, inventario, reportes y seguridad.'
                      : 'Hola ${session.user?.nombre ?? 'Usuario'}. Accede a operaciones, maestros, inventario y reportes.',
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.72),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ErrorBanner(message: _error),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _StatsGrid(
                    tiles: isAdmin
                        ? [
                            _StatData(
                              label: 'Productos',
                              value: _stats['productos'] ?? 0,
                              icon: Icons.phone_android,
                            ),
                            _StatData(
                              label: 'Proveedores',
                              value: _stats['proveedores'] ?? 0,
                              icon: Icons.local_shipping,
                            ),
                            _StatData(
                              label: 'Clientes',
                              value: _stats['clientes'] ?? 0,
                              icon: Icons.groups,
                            ),
                            _StatData(
                              label: 'Ventas',
                              value: _stats['ventas'] ?? 0,
                              icon: Icons.point_of_sale,
                            ),
                          ]
                        : [
                            _StatData(
                              label: 'Compras y ventas',
                              value: _stats['ventas'] ?? 0,
                              icon: Icons.swap_horiz,
                            ),
                            _StatData(
                              label: 'Inventario',
                              value: _stats['productos'] ?? 0,
                              icon: Icons.inventory_2,
                            ),
                            _StatData(
                              label: 'Clientes',
                              value: _stats['clientes'] ?? 0,
                              icon: Icons.groups,
                            ),
                            _StatData(
                              label: 'Reportes',
                              value: _stats['ventas'] ?? 0,
                              icon: Icons.bar_chart,
                            ),
                          ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final api = SessionScope.read(context).api;
      final results = await Future.wait([
        api.list('/productos'),
        api.list('/proveedores'),
        api.list('/clientes'),
        api.list('/ventas'),
      ]);
      if (!mounted) return;
      setState(() {
        _stats['productos'] = results[0].length;
        _stats['proveedores'] = results[1].length;
        _stats['clientes'] = results[2].length;
        _stats['ventas'] = results[3].length;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.tiles});

  final List<_StatData> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 720
            ? 4
            : width >= 300
            ? 2
            : 1;
        final tileHeight = width < 340 ? 124.0 : 112.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) {
            final tile = tiles[index];
            return _StatTile(
              label: tile.label,
              value: tile.value,
              icon: tile.icon,
            );
          },
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.96),
            const Color(0xFFEAF5F8).withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 90;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: compact ? 26 : 30,
                child: Row(
                  children: [
                    Container(
                      width: compact ? 28 : 34,
                      height: compact ? 28 : 34,
                      decoration: BoxDecoration(
                        color: AppTheme.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.blue,
                        size: compact ? 17 : 20,
                      ),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value.toString(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    label,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.76),
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
