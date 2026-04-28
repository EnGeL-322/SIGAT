import { Routes } from '@angular/router';
import { LoginComponent } from './shared/features/auth/login/login';
import { RegisterComponent } from './shared/features/auth/register/register';
import { DashboardLayoutComponent } from './layout/dashboard-layout/dashboard-layout';
import { DashboardHomeComponent } from './shared/features/dashboard/dashboard-home/dashboard-home';
import { ProductosListComponent } from './shared/features/productos/productos-list/productos-list';
import { ProveedoresListComponent } from './shared/features/proveedores/proveedores-list/proveedores-list';
import { ClientesListComponent } from './shared/features/clientes/clientes-list/clientes-list';
import { InventarioListComponent } from './shared/features/inventario/inventario-list/inventario-list';
import { ComprasListComponent } from './shared/features/compras/compras-list/compras-list';
import { ComprasFormComponent } from './shared/features/compras/compras-form/compras-form';
import { VentasListComponent } from './shared/features/ventas/ventas-list/ventas-list';
import { VentasFormComponent } from './shared/features/ventas/ventas-form/ventas-form';
import { UsuariosListComponent } from './shared/features/usuarios/usuarios-list/usuarios-list';
import { ReporteStockComponent } from './shared/features/reportes/reporte-stock/reporte-stock';
import { ReporteVentasComponent } from './shared/features/reportes/reporte-ventas/reporte-ventas';
import { ReporteBajoStockComponent } from './shared/features/reportes/reporte-bajo-stock/reporte-bajo-stock';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },

  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },

  {
    path: '',
    component: DashboardLayoutComponent,
    children: [
      { path: 'dashboard', component: DashboardHomeComponent },
      { path: 'productos', component: ProductosListComponent },
      { path: 'proveedores', component: ProveedoresListComponent },
      { path: 'clientes', component: ClientesListComponent },
      { path: 'inventario', component: InventarioListComponent },
      { path: 'compras', component: ComprasListComponent },
      { path: 'compras/nueva', component: ComprasFormComponent },
      { path: 'ventas', component: VentasListComponent },
      { path: 'ventas/nueva', component: VentasFormComponent },
      { path: 'reportes/stock', component: ReporteStockComponent },
      { path: 'reportes/ventas', component: ReporteVentasComponent },
      { path: 'reportes/bajo-stock', component: ReporteBajoStockComponent },
      { path: 'usuarios', component: UsuariosListComponent }
    ]
  },

  { path: '**', redirectTo: 'login' }
];
