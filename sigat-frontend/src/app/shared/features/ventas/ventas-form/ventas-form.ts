import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-ventas-form',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './ventas-form.html',
  styleUrl: './ventas-form.css'
})
export class VentasFormComponent implements OnInit {
  clientes: any[] = [];
  productos: any[] = [];
  detalles: any[] = [];
  error = '';

  venta = {
    clienteId: null as number | null,
    fecha: new Date().toISOString().slice(0, 10),
    tipoComprobante: '',
    dni: '',
    vendedor: 'SIGAT'
  };

  detalle = {
    productoId: null as number | null,
    cantidad: 1,
    precioUnitario: 0
  };

  constructor(private api: ApiService, private router: Router, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.api.obtenerClientes().subscribe((r: any) => {
      this.clientes = r?.datos || [];
      this.cdr.detectChanges();
    });
    this.api.obtenerProductos().subscribe((r: any) => {
      this.productos = r?.datos || [];
      this.cdr.detectChanges();
    });
  }

  clienteCambiado(): void {
    const cliente = this.clientes.find(c => c.id == this.venta.clienteId);
    this.venta.dni = cliente?.cedula || '';
  }

  agregarDetalle(): void {
    this.error = '';
    if (!this.detalle.productoId || !this.detalle.cantidad || !this.detalle.precioUnitario) return;

    const producto = this.productos.find(p => p.id == this.detalle.productoId);
    if (producto?.stockActual !== undefined && this.detalle.cantidad > producto.stockActual) {
      this.error = `Stock insuficiente. Disponible: ${producto.stockActual}`;
      return;
    }

    this.detalles.push({
      productoId: this.detalle.productoId,
      productoNombre: producto?.nombre,
      cantidad: this.detalle.cantidad,
      precioUnitario: this.detalle.precioUnitario,
      subtotal: this.detalle.cantidad * this.detalle.precioUnitario
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
    if (!this.venta.clienteId || this.detalles.length === 0) return;

    const payload = {
      venta: { clienteId: this.venta.clienteId },
      detalles: this.detalles.map(d => ({
        productoId: d.productoId,
        cantidad: d.cantidad,
        precioUnitario: d.precioUnitario
      }))
    };

    this.api.crearVenta(payload).subscribe({
      next: () => this.router.navigate(['/ventas']),
      error: (err) => {
        this.error = err?.error?.mensaje || 'No se pudo registrar la venta.';
        this.cdr.detectChanges();
      }
    });
  }

  total(): number {
    return this.detalles.reduce((sum, d) => sum + d.subtotal, 0);
  }
}
