import 'package:flutter/material.dart';

class SigatMenuItem {
  const SigatMenuItem({
    required this.label,
    required this.group,
    required this.route,
    required this.icon,
    required this.keywords,
    this.adminOnly = false,
  });

  final String label;
  final String group;
  final String route;
  final IconData icon;
  final List<String> keywords;
  final bool adminOnly;
}

const sigatMenuItems = <SigatMenuItem>[
  SigatMenuItem(
    label: 'Dashboard',
    group: 'Inicio',
    route: '/dashboard',
    icon: Icons.dashboard_outlined,
    keywords: ['panel', 'inicio', 'home', 'dashboard'],
  ),
  SigatMenuItem(
    label: 'Compras',
    group: 'Operaciones',
    route: '/compras',
    icon: Icons.shopping_bag_outlined,
    keywords: ['compra', 'compras', 'ingreso', 'proveedor'],
  ),
  SigatMenuItem(
    label: 'Ventas',
    group: 'Operaciones',
    route: '/ventas',
    icon: Icons.point_of_sale_outlined,
    keywords: ['venta', 'ventas', 'salida', 'cliente'],
  ),
  SigatMenuItem(
    label: 'Producto',
    group: 'Maestros',
    route: '/productos',
    icon: Icons.phone_android_outlined,
    keywords: ['producto', 'productos', 'celular', 'equipo'],
  ),
  SigatMenuItem(
    label: 'Proveedores',
    group: 'Maestros',
    route: '/proveedores',
    icon: Icons.local_shipping_outlined,
    keywords: ['proveedor', 'proveedores', 'ruc'],
  ),
  SigatMenuItem(
    label: 'Clientes',
    group: 'Maestros',
    route: '/clientes',
    icon: Icons.groups_outlined,
    keywords: ['cliente', 'clientes', 'dni', 'cedula'],
  ),
  SigatMenuItem(
    label: 'Stock general',
    group: 'Inventario',
    route: '/inventario',
    icon: Icons.inventory_2_outlined,
    keywords: ['stock', 'inventario', 'imei', 'equipos'],
  ),
  SigatMenuItem(
    label: 'Reporte ventas',
    group: 'Reportes',
    route: '/reportes/ventas',
    icon: Icons.bar_chart_outlined,
    keywords: ['reporte', 'reportes', 'venta', 'ventas'],
  ),
  SigatMenuItem(
    label: 'Reporte compras',
    group: 'Reportes',
    route: '/reportes/compras',
    icon: Icons.shopping_bag_outlined,
    keywords: ['reporte', 'reportes', 'compra', 'compras', 'proveedor'],
  ),
  SigatMenuItem(
    label: 'Bajo stock',
    group: 'Reportes',
    route: '/reportes/bajo-stock',
    icon: Icons.warning_amber_outlined,
    keywords: ['bajo stock', 'agotado', 'minimo', 'reportes'],
  ),
  SigatMenuItem(
    label: 'Usuarios',
    group: 'Seguridad',
    route: '/usuarios',
    icon: Icons.admin_panel_settings_outlined,
    keywords: ['usuario', 'usuarios', 'seguridad', 'roles', 'admin'],
    adminOnly: true,
  ),
];

List<SigatMenuItem> visibleMenuItems(bool isAdmin) {
  return sigatMenuItems.where((item) => !item.adminOnly || isAdmin).toList();
}

Map<String, List<SigatMenuItem>> groupedMenuItems(bool isAdmin) {
  final groups = <String, List<SigatMenuItem>>{};
  for (final item in visibleMenuItems(isAdmin)) {
    groups.putIfAbsent(item.group, () => []).add(item);
  }
  return groups;
}
