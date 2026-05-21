import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-compras-list',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './compras-list.html',
  styleUrl: './compras-list.css'
})
export class ComprasListComponent implements OnInit {
  compras: any[] = [];
  detalles: any[] = [];
  detailModal = false;
  selected: any = null;
  error = '';

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
