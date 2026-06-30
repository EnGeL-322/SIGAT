import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';
import { extractError } from '../../../utils/extract-error';

@Component({
  selector: 'app-ventas-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './ventas-list.html',
  styleUrl: './ventas-list.css'
})
export class VentasListComponent implements OnInit {
  ventas: any[] = [];
  detalles: any[] = [];
  selectedPhone: any = null;
  detailModal = false;
  phoneModal = false;
  selected: any = null;
  error = '';
  busqueda = '';
  busquedaImei = '';
  itemsPorPagina = 10;
  paginaActual = 1;

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerVentas().subscribe({
      next: (res: any) => {
        this.ventas = res?.datos || [];
        this.paginaActual = 1;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = extractError(err, 'No se pudieron cargar las ventas');
        this.cdr.detectChanges();
      }
    });
  }

  verDetalle(item: any): void {
    this.error = '';
    this.selected = item;
    this.busquedaImei = '';
    this.api.obtenerDetallesVenta(item.id).subscribe({
      next: (res: any) => {
        this.detalles = res?.datos || [];
        this.detailModal = true;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = extractError(err, 'No se pudo cargar el detalle de la venta');
        this.cdr.detectChanges();
      }
    });
  }

  verTelefono(detalle: any): void {
    this.selectedPhone = detalle;
    this.phoneModal = true;
  }

  filtrar(): void {
    this.paginaActual = 1;
    this.cdr.detectChanges();
  }

  get ventasFiltradas(): any[] {
    const q = this.busqueda.trim().toLowerCase();
    if (!q) return this.ventas;
    return this.ventas.filter(v =>
      (v.clienteNombre || '').toLowerCase().includes(q) ||
      (v.numeroVenta || '').toLowerCase().includes(q) ||
      (v.vendedorNombre || '').toLowerCase().includes(q)
    );
  }

  get detallesFiltrados(): any[] {
    const q = this.busquedaImei.trim().toLowerCase();
    if (!q) return this.detalles;
    return this.detalles.filter(d =>
      (d.imeiNumero || '').toLowerCase().includes(q) ||
      (d.productoNombre || '').toLowerCase().includes(q)
    );
  }

  get ventasPaginadas(): any[] {
    const inicio = (this.paginaActual - 1) * this.itemsPorPagina;
    return this.ventasFiltradas.slice(inicio, inicio + this.itemsPorPagina);
  }

  get totalPaginas(): number {
    return Math.max(1, Math.ceil(this.ventasFiltradas.length / this.itemsPorPagina));
  }

  get paginas(): number[] {
    return Array.from({ length: this.totalPaginas }, (_, index) => index + 1);
  }

  get inicioPagina(): number {
    if (!this.ventasFiltradas.length) return 0;
    return (this.paginaActual - 1) * this.itemsPorPagina + 1;
  }

  get finPagina(): number {
    return Math.min(this.paginaActual * this.itemsPorPagina, this.ventasFiltradas.length);
  }

  cambiarPagina(pagina: number): void {
    if (pagina < 1 || pagina > this.totalPaginas) return;
    this.paginaActual = pagina;
  }

  remove(id: number): void {
    const confirmed = confirm('Eliminar esta venta devolvera sus IMEI al stock. Deseas continuar?');
    if (!confirmed) return;

    this.error = '';
    this.api.eliminarVenta(id).subscribe({
      next: () => {
        if (this.selected?.id === id) {
          this.detailModal = false;
          this.selected = null;
          this.detalles = [];
        }
        this.load();
      },
      error: (err) => {
        this.error = extractError(err, 'No se pudo eliminar la venta');
        this.cdr.detectChanges();
      }
    });
  }
}
