import 'package:flutter/material.dart';

import '../../core/offline/sync_service.dart';
import '../../core/session/session_controller.dart';
import '../navigation/sigat_menu.dart';
import '../theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.activeRoute,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final String activeRoute;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.watch(context);

    return Scaffold(
      drawer: _SigatDrawer(activeRoute: activeRoute),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel SIGAT',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            Text(
              session.user?.roleLabel ?? 'MOVIL',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.62),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => showSearch(
              context: context,
              delegate: SigatSearchDelegate(session.isAdmin),
            ),
            icon: const Icon(Icons.search),
            tooltip: 'Buscar modulo',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset('assets/images/logo-sigat.png', width: 64),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF14365D), Color(0xFF48A6C6), Color(0xFFF3F7FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const _OfflineBanner(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso flotante que indica el modo sin conexion y los cambios pendientes
/// de sincronizar. Se oculta solo cuando hay conexion y nada en cola.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final sync = SyncScope.maybeOf(context);
    if (sync == null) return const SizedBox.shrink();

    final offline = sync.isOffline;
    final pending = sync.pendingCount;
    if (!offline && pending == 0) return const SizedBox.shrink();

    final color = offline ? const Color(0xFFB7791F) : AppTheme.blue;
    final icon = sync.isSyncing
        ? Icons.sync
        : offline
        ? Icons.cloud_off_outlined
        : Icons.cloud_sync_outlined;

    final parts = <String>[
      if (offline) 'Sin conexion' else 'Conectado',
      if (pending > 0)
        '$pending cambio${pending == 1 ? '' : 's'} por sincronizar',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          if (pending > 0 && !offline)
            TextButton(
              onPressed: sync.isSyncing ? null : () => sync.flush(),
              child: Text(sync.isSyncing ? 'Sincronizando...' : 'Sincronizar'),
            ),
        ],
      ),
    );
  }
}

class _SigatDrawer extends StatelessWidget {
  const _SigatDrawer({required this.activeRoute});

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.watch(context);
    final groups = groupedMenuItems(session.isAdmin);

    return Drawer(
      backgroundColor: const Color(0xFFF7FAFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Image.asset(
                'assets/images/logo-sigat.png',
                height: 78,
                alignment: Alignment.centerLeft,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final group in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                      child: Text(
                        group.key.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.ink.withValues(alpha: 0.58),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                    ),
                    for (final item in group.value)
                      ListTile(
                        minVerticalPadding: 10,
                        selected: item.route == activeRoute,
                        leading: Icon(item.icon),
                        title: Text(item.label),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (ModalRoute.of(context)?.settings.name !=
                              item.route) {
                            Navigator.pushReplacementNamed(context, item.route);
                          }
                        },
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: () {
                  session.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SigatSearchDelegate extends SearchDelegate<void> {
  SigatSearchDelegate(this.isAdmin);

  final bool isAdmin;

  @override
  String? get searchFieldLabel => 'Buscar modulo';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '',
        icon: const Icon(Icons.close),
        tooltip: 'Limpiar',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Atras',
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final term = _normalize(query);
    final items = visibleMenuItems(isAdmin)
        .where((item) {
          if (term.isEmpty) return true;
          final values = [
            item.label,
            item.group,
            ...item.keywords,
          ].map(_normalize);
          return values.any((value) => value.contains(term));
        })
        .take(8)
        .toList();

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(item.label),
          subtitle: Text(item.group),
          onTap: () {
            close(context, null);
            Navigator.pushReplacementNamed(context, item.route);
          },
        );
      },
    );
  }

  String _normalize(String value) => value.toLowerCase().trim();
}
