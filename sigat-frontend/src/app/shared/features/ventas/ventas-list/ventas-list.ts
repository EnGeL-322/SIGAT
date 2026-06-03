import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

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
  busquedaImei = '';

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerVentas().subscribe({
      next: (res: any) => {
        this.ventas = res?.datos || [];
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = this.extractError(err, 'No se pudieron cargar las ventas');
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
        this.error = this.extractError(err, 'No se pudo cargar el detalle de la venta');
        this.cdr.detectChanges();
      }
    });
  }

  verTelefono(detalle: any): void {
    this.selectedPhone = detalle;
    this.phoneModal = true;
  }

  get detallesFiltrados(): any[] {
    const q = this.busquedaImei.trim().toLowerCase();
    if (!q) return this.detalles;
    return this.detalles.filter(d =>
      (d.imeiNumero || '').toLowerCase().includes(q) ||
      (d.productoNombre || '').toLowerCase().includes(q)
    );
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
        this.error = this.extractError(err, 'No se pudo eliminar la venta');
        this.cdr.detectChanges();
      }
    });
  }

  private extractError(err: any, fallback: string): string {
    return err?.error?.mensaje || err?.error?.message || err?.message || fallback;
  }
}
