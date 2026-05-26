import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/data_widgets.dart';
import 'entity_list_page.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) => EntityListPage(definition: _products);
}

class ProvidersPage extends StatelessWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context) => EntityListPage(definition: _providers);
}

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) => EntityListPage(definition: _clients);
}

final _products = EntityDefinition(
  eyebrow: 'Maestros',
  title: 'Producto',
  createLabel: 'Agregar producto',
  emptyLabel: 'No hay productos registrados',
  searchKeys: const ['nombre', 'codigo', 'marca', 'modelo'],
  fields: const [
    EntityField(key: 'marca', label: 'Marca'),
    EntityField(key: 'modelo', label: 'Modelo'),
    EntityField(key: 'nombre', label: 'Nombre'),
    EntityField(key: 'codigo', label: 'Codigo'),
    EntityField(
      key: 'precio',
      label: 'Precio',
      type: EntityFieldType.decimal,
      defaultValue: 0,
    ),
    EntityField(
      key: 'stockMinimo',
      label: 'Stock minimo',
      type: EntityFieldType.integer,
      defaultValue: 10,
    ),
    EntityField(
      key: 'descripcion',
      label: 'Descripcion',
      type: EntityFieldType.multiline,
      required: false,
    ),
  ],
  details: [
    const EntityDetail('Nombre', 'nombre'),
    const EntityDetail('Marca', 'marca'),
    const EntityDetail('Modelo', 'modelo'),
    const EntityDetail('Codigo', 'codigo'),
    EntityDetail('Precio', 'precio', formatter: formatMoney),
    const EntityDetail('Stock', 'stockActual'),
    const EntityDetail('Stock minimo', 'stockMinimo'),
    const EntityDetail('Descripcion', 'descripcion'),
  ],
  load: (api) => api.list('/productos'),
  create: (api, payload, _) async => api.post('/productos', payload),
  update: (api, payload, id) async => api.put('/productos/$id', payload),
  remove: (api, id) async => api.delete('/productos/$id'),
  titleBuilder: (item) =>
      '${item['marca'] ?? ''} ${item['modelo'] ?? ''}'.trim(),
  subtitleBuilder: (item) =>
      '${item['codigo'] ?? ''} - ${formatMoney(item['precio'])}',
  statusBuilder: (item) {
    final stock = _asNum(item['stockActual']).toInt();
    if (stock <= 0) {
      return const StatusChip(label: 'AGOTADO', color: AppTheme.rose);
    }
    if (stock <= 5) {
      return const StatusChip(label: 'STOCK BAJO', color: Color(0xFFB7791F));
    }
    return const StatusChip(label: 'DISPONIBLE', color: Color(0xFF14804A));
  },
);

final _providers = EntityDefinition(
  eyebrow: 'Maestros',
  title: 'Proveedores',
  createLabel: 'Agregar proveedor',
  emptyLabel: 'No hay proveedores registrados',
  searchKeys: const ['nombre', 'ruc', 'email', 'telefono'],
  fields: const [
    EntityField(key: 'nombre', label: 'Nombre'),
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
  ],
  details: const [
    EntityDetail('Nombre', 'nombre'),
    EntityDetail('RUC', 'ruc'),
    EntityDetail('Email', 'email'),
    EntityDetail('Telefono', 'telefono'),
    EntityDetail('Contacto', 'contacto'),
    EntityDetail('Direccion', 'direccion'),
  ],
  load: (api) => api.list('/proveedores'),
  create: (api, payload, _) async => api.post('/proveedores', payload),
  update: (api, payload, id) async => api.put('/proveedores/$id', payload),
  remove: (api, id) async => api.delete('/proveedores/$id'),
  titleBuilder: (item) => item['nombre']?.toString() ?? '',
  subtitleBuilder: (item) => '${item['ruc'] ?? ''} - ${item['telefono'] ?? ''}',
);

final _clients = EntityDefinition(
  eyebrow: 'Maestros',
  title: 'Clientes',
  createLabel: 'Agregar cliente',
  emptyLabel: 'No hay clientes registrados',
  searchKeys: const ['nombre', 'apellido', 'cedula', 'email'],
  fields: const [
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
  ],
  details: const [
    EntityDetail('Nombre', 'nombre'),
    EntityDetail('Apellido', 'apellido'),
    EntityDetail('Cedula', 'cedula'),
    EntityDetail('Email', 'email'),
    EntityDetail('Telefono', 'telefono'),
    EntityDetail('Direccion', 'direccion'),
  ],
  load: (api) => api.list('/clientes'),
  create: (api, payload, _) async => api.post('/clientes', payload),
  update: (api, payload, id) async => api.put('/clientes/$id', payload),
  remove: (api, id) async => api.delete('/clientes/$id'),
  titleBuilder: (item) =>
      '${item['nombre'] ?? ''} ${item['apellido'] ?? ''}'.trim(),
  subtitleBuilder: (item) =>
      '${item['cedula'] ?? ''} - ${item['telefono'] ?? ''}',
);

num _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
