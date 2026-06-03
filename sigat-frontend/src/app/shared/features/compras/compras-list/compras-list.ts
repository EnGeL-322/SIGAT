import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-compras-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './compras-list.html',
  styleUrl: './compras-list.css'
})
export class ComprasListComponent implements OnInit {
  compras: any[] = [];
  detalles: any[] = [];
  detailModal = false;
  selected: any = null;
  error = '';
  imeiModal = false;
  imeisDelDetalle: any[] = [];
  detalleSeleccionado: any = null;
  busquedaImei = '';

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerCompras().subscribe({
      next: (res: any) => {
        this.compras = res?.datos || [];
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = this.extractError(err, 'No se pudieron cargar las compras');
        this.cdr.detectChanges();
      }
    });
  }

  verDetalle(item: any): void {
    this.error = '';
    this.selected = item;
    this.api.obtenerDetallesCompra(item.id).subscribe({
      next: (res: any) => {
        this.detalles = res?.datos || [];
        this.detailModal = true;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = this.extractError(err, 'No se pudo cargar el detalle de la compra');
        this.cdr.detectChanges();
      }
    });
  }

  verIMEIs(detalle: any): void {
    // El detalle de compra ya incluye sus IMEIs (cargados en verDetalle),
    // por lo que no se requiere una peticion HTTP adicional.
    this.detalleSeleccionado = detalle;
    this.imeisDelDetalle = detalle?.imeis || [];
    this.busquedaImei = '';
    this.imeiModal = true;
    this.cdr.detectChanges();
  }

  get imeisFiltrados(): any[] {
    const q = this.busquedaImei.trim().toLowerCase();
    if (!q) return this.imeisDelDetalle;
    return this.imeisDelDetalle.filter(imei =>
      (imei.numero || '').toLowerCase().includes(q)
    );
  }

  remove(id: number): void {
    const confirmed = confirm('Eliminar esta compra quitara sus IMEI y reducira el stock. Solo se permite si no tiene equipos vendidos. Deseas continuar?');
    if (!confirmed) return;

    this.error = '';
    this.api.eliminarCompra(id).subscribe({
      next: () => {
        if (this.selected?.id === id) {
          this.detailModal = false;
          this.selected = null;
          this.detalles = [];
        }
        this.load();
      },
      error: (err) => {
        this.error = this.extractError(err, 'No se pudo eliminar la compra');
        this.cdr.detectChanges();
      }
    });
  }

  private extractError(err: any, fallback: string): string {
    return err?.error?.mensaje || err?.error?.message || err?.message || fallback;
  }
}
