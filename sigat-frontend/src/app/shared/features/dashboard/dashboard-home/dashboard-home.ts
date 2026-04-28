import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { catchError, forkJoin, of } from 'rxjs';
import { ApiService } from '../../../../core/api.service';

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

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.loadStats();
  }

  loadStats(): void {
    forkJoin({
      productos: this.api.obtenerProductos().pipe(catchError(() => of({ datos: [] }))),
      proveedores: this.api.obtenerProveedores().pipe(catchError(() => of({ datos: [] }))),
      clientes: this.api.obtenerClientes().pipe(catchError(() => of({ datos: [] }))),
      ventas: this.api.obtenerVentas().pipe(catchError(() => of({ datos: [] })))
    }).subscribe((res: any) => {
      this.productos = this.countItems(res.productos);
      this.proveedores = this.countItems(res.proveedores);
      this.clientes = this.countItems(res.clientes);
      this.ventas = this.countItems(res.ventas);
      this.cdr.detectChanges();
    });
  }

  private countItems(response: any): number {
    if (Array.isArray(response)) return response.length;
    if (Array.isArray(response?.datos)) return response.datos.length;
    if (Array.isArray(response?.data)) return response.data.length;
    if (Array.isArray(response?.content)) return response.content.length;
    return 0;
  }
}
