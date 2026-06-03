import { Routes } from '@angular/router';
import { LoginComponent } from './shared/features/auth/login/login';
import { RegisterComponent } from './shared/features/auth/register/register';
import { ForgotPasswordComponent } from './shared/features/auth/forgot-password/forgot-password';
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
import { ReporteVentasComponent } from './shared/features/reportes/reporte-ventas/reporte-ventas';
import { ReporteComprasComponent } from './shared/features/reportes/reporte-compras/reporte-compras';
import { ReporteBajoStockComponent } from './shared/features/reportes/reporte-bajo-stock/reporte-bajo-stock';
import { adminGuard } from './core/admin.guard';
import { authChildGuard, authGuard } from './core/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },

  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: 'forgot-password', component: ForgotPasswordComponent },

  {
    path: '',
    component: DashboardLayoutComponent,
    canActivate: [authGuard],
    canActivateChild: [authChildGuard],
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
      { path: 'reportes', redirectTo: 'reportes/ventas', pathMatch: 'full' },
      { path: 'reportes/stock', redirectTo: 'reportes/ventas', pathMatch: 'full' },
      { path: 'reportes/ventas', component: ReporteVentasComponent },
      { path: 'reportes/compras', component: ReporteComprasComponent },
      { path: 'reportes/bajo-stock', component: ReporteBajoStockComponent },
      { path: 'usuarios', component: UsuariosListComponent, canActivate: [adminGuard] }
    ]
  },

  { path: '**', redirectTo: 'login' }
];
