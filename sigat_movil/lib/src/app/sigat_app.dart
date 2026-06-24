import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/session/session_controller.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/catalog/catalog_pages.dart';
import '../features/catalog/users_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/inventory/inventory_page.dart';
import '../features/operations/operations_pages.dart';
import '../features/reports/reports_pages.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_shell.dart';

class SigatApp extends StatefulWidget {
  const SigatApp({super.key});

  @override
  State<SigatApp> createState() => _SigatAppState();
}

class _SigatAppState extends State<SigatApp> {
  late final ApiClient _api;
  late final SessionController _session;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _session = SessionController(_api);
    _api.onUnauthorized = _handleUnauthorized;
    _session.restoreSession();
  }

  @override
  void dispose() {
    _api.close();
    _session.dispose();
    super.dispose();
  }

  void _handleUnauthorized() {
    if (!_session.isAuthenticated) return;
    _session.logout();
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: _session,
      child: AnimatedBuilder(
        animation: _session,
        builder: (context, _) {
          if (_session.isRestoring) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return MaterialApp(
            title: 'SIGAT Movil',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            navigatorKey: _navigatorKey,
            onGenerateRoute: _route,
          );
        },
      ),
    );
  }

  Route<dynamic> _route(RouteSettings settings) {
    final requested = settings.name ?? '/';
    final route = requested == '/'
        ? (_session.isAuthenticated ? '/dashboard' : '/login')
        : requested;

    if (!_isAuthRoute(route) && !_session.isAuthenticated) {
      return _page(const LoginPage(), name: '/login');
    }

    if (_isAuthRoute(route) && _session.isAuthenticated) {
      return _page(
        _shell('/dashboard', 'Dashboard', const DashboardPage()),
        name: '/dashboard',
      );
    }

    if (route == '/usuarios' && !_session.isAdmin) {
      return _page(
        _shell('/dashboard', 'Dashboard', const DashboardPage()),
        name: '/dashboard',
      );
    }

    return switch (route) {
      '/login' => _page(const LoginPage(), name: route),
      '/register' => _page(const RegisterPage(), name: route),
      '/forgot-password' => _page(const ForgotPasswordPage(), name: route),
      '/dashboard' => _page(
        _shell(route, 'Dashboard', const DashboardPage()),
        name: route,
      ),
      '/productos' => _page(
        _shell(route, 'Producto', const ProductsPage()),
        name: route,
      ),
      '/proveedores' => _page(
        _shell(route, 'Proveedores', const ProvidersPage()),
        name: route,
      ),
      '/clientes' => _page(
        _shell(route, 'Clientes', const ClientsPage()),
        name: route,
      ),
      '/inventario' => _page(
        _shell(route, 'Stock general', const InventoryPage()),
        name: route,
      ),
      '/compras' => _page(
        _shell(route, 'Compras', const PurchasesPage()),
        name: route,
      ),
      '/compras/nueva' => _page(
        _shell('/compras', 'Nueva compra', const PurchaseFormPage()),
        name: route,
      ),
      '/ventas' => _page(
        _shell(route, 'Ventas', const SalesPage()),
        name: route,
      ),
      '/ventas/nueva' => _page(
        _shell('/ventas', 'Nueva venta', const SaleFormPage()),
        name: route,
      ),
      '/reportes/ventas' => _page(
        _shell(route, 'Reporte ventas', const SalesReportPage()),
        name: route,
      ),
      '/reportes/compras' => _page(
        _shell(route, 'Reporte compras', const PurchasesReportPage()),
        name: route,
      ),
      '/reportes/bajo-stock' => _page(
        _shell(route, 'Bajo stock', const LowStockReportPage()),
        name: route,
      ),
      '/usuarios' => _page(
        _shell(route, 'Usuarios', const UsersPage()),
        name: route,
      ),
      _ => _page(const LoginPage(), name: '/login'),
    };
  }

  bool _isAuthRoute(String route) {
    return route == '/login' ||
        route == '/register' ||
        route == '/forgot-password';
  }

  Widget _shell(String activeRoute, String title, Widget child) {
    return AppShell(activeRoute: activeRoute, title: title, child: child);
  }

  MaterialPageRoute<dynamic> _page(Widget child, {required String name}) {
    return MaterialPageRoute<dynamic>(
      settings: RouteSettings(name: name),
      builder: (_) => child,
    );
  }
}
