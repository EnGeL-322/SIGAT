import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-compras-form',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './compras-form.html',
  styleUrl: './compras-form.css'
})
export class ComprasFormComponent implements OnInit {
  proveedores: any[] = [];
  productos: any[] = [];
  detalles: any[] = [];
  error = '';

  compra = {
    proveedorId: null as number | null,
    fecha: new Date().toISOString().slice(0, 10),
    tipoComprobante: '',
    numeroComprobante: '',
    observacion: ''
  };

  detalle = {
    productoId: null as number | null,
    cantidad: 1,
    precioUnitario: 0
  };

  constructor(private api: ApiService, private router: Router, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.api.obtenerProveedores().subscribe((r: any) => {
      this.proveedores = r?.datos || [];
      this.cdr.detectChanges();
    });
    this.api.obtenerProductos().subscribe((r: any) => {
      this.productos = r?.datos || [];
      this.cdr.detectChanges();
    });
  }

  productoCambiado(): void {
    const producto = this.productos.find(p => p.id == this.detalle.productoId);
    this.detalle.precioUnitario = Number(producto?.precio || 0);
    this.cdr.detectChanges();
  }

  agregarDetalle(): void {
    this.error = '';
    if (!this.detalle.productoId || !this.detalle.cantidad || !this.detalle.precioUnitario) return;

    const producto = this.productos.find(p => p.id == this.detalle.productoId);

    this.detalles.push({
      productoId: this.detalle.productoId,
      productoNombre: producto?.nombre,
      cantidad: this.detalle.cantidad,
      precioUnitario: this.detalle.precioUnitario
    });

    this.detalle = {
      productoId: null,
      cantidad: 1,
      precioUnitario: 0
    };
  }

  eliminarDetalle(index: number): void {
    this.detalles.splice(index, 1);
  }

  guardar(): void {
    this.error = '';
    if (!this.compra.proveedorId || this.detalles.length === 0) return;

    const payload = {
      compra: { proveedorId: this.compra.proveedorId },
      detalles: this.detalles.map(d => ({
        productoId: d.productoId,
        cantidad: d.cantidad,
        precioUnitario: d.precioUnitario
      }))
    };

    this.api.crearCompra(payload).subscribe({
      next: () => this.router.navigate(['/compras']),
      error: (err) => {
        this.error = err?.error?.mensaje || 'No se pudo registrar la compra.';
        this.cdr.detectChanges();
      }
    });
  }

  total(): number {
    return this.detalles.reduce((sum, d) => sum + (d.cantidad * d.precioUnitario), 0);
  }

  imeisCargados(detalle: any): string {
    return `${detalle.cantidad}/${detalle.cantidad}`;
  }

  estadoDetalle(detalle: any): string {
    return detalle.cantidad > 0 ? 'Terminado' : 'En proceso';
  }
}
