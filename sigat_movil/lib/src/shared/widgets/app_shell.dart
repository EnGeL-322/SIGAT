import 'package:flutter/material.dart';

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
            colors: [Color(0xFFAEB9CD), Color(0xFFD4DBEA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
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
                          ),
                    ),
                    const SizedBox(height: 12),
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

class _SigatDrawer extends StatelessWidget {
  const _SigatDrawer({required this.activeRoute});

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.watch(context);
    final groups = groupedMenuItems(session.isAdmin);

    return Drawer(
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
