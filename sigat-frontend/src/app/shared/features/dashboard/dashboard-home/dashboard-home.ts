import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from '../../../../core/api.service';
import { AuthService } from '../../../../core/auth.service';

@Component({
  selector: 'app-dashboard-home',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard-home.html',
  styleUrl: './dashboard-home.css'
})
export class DashboardHomeComponent implements OnInit {
  productos = 0;
  proveedores = 0;
  clientes = 0;
  ventas = 0;

  constructor(private api: ApiService, private authService: AuthService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.loadStats();
  }

  loadStats(): void {
    this.api.obtenerDashboardStats().subscribe((res: any) => {
      const stats = res?.datos || {};
      this.productos = stats.productos || 0;
      this.proveedores = stats.proveedores || 0;
      this.clientes = stats.clientes || 0;
      this.ventas = stats.ventas || 0;
      this.cdr.detectChanges();
    });
  }

  get isAdmin(): boolean {
    return this.authService.isAdmin();
  }

  get roleLabel(): string {
    return this.isAdmin ? 'Vista admin' : 'Vista trabajador';
  }

  get userName(): string {
    return this.authService.getUser()?.nombre || 'Usuario';
  }
}
