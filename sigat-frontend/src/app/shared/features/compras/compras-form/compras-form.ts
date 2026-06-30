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

  busquedaProveedor = '';
  mostrarDropdownProveedor = false;
  proveedoresFiltrados: any[] = [];

  busquedaProducto = '';
  mostrarDropdownProducto = false;
  productosFiltrados: any[] = [];

  showProveedorModal = false;
  guardandoProveedor = false;
  proveedorError = '';
  nuevoProveedor = this.proveedorVacio();

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
    this.cargarProveedores();
    this.api.obtenerProductos().subscribe((r: any) => {
      this.productos = r?.datos || [];
      this.cdr.detectChanges();
    });
  }

  private proveedorVacio() {
    return { nombre: '', ruc: '', contacto: '', telefono: '', email: '', direccion: '' };
  }

  cargarProveedores(seleccionar?: any): void {
    this.api.obtenerProveedores().subscribe((r: any) => {
      this.proveedores = r?.datos || [];
      if (seleccionar) {
        const match = this.proveedores.find(p =>
          (seleccionar.id != null && p.id === seleccionar.id) ||
          (seleccionar.ruc && p.ruc === seleccionar.ruc));
        if (match) {
          this.compra.proveedorId = match.id;
          this.busquedaProveedor = match.nombre;
        }
      }
      this.cdr.detectChanges();
    });
  }

  // --- Proveedor dropdown ---

  abrirDropdownProveedor(): void {
    this.proveedoresFiltrados = [...this.proveedores];
    this.mostrarDropdownProveedor = true;
  }

  filtrarProveedores(): void {
    const q = this.busquedaProveedor.toLowerCase();
    this.proveedoresFiltrados = this.proveedores.filter(p =>
      (p.nombre || '').toLowerCase().includes(q) ||
      (p.ruc || '').toLowerCase().includes(q) ||
      (p.contacto || '').toLowerCase().includes(q)
    );
    this.mostrarDropdownProveedor = true;
    if (!this.busquedaProveedor) {
      this.compra.proveedorId = null;
    }
  }

  seleccionarProveedor(p: any): void {
    this.compra.proveedorId = p.id;
    this.busquedaProveedor = p.nombre;
    this.mostrarDropdownProveedor = false;
    this.cdr.detectChanges();
  }

  cerrarDropdownProveedor(): void {
    setTimeout(() => {
      this.mostrarDropdownProveedor = false;
      this.cdr.detectChanges();
    }, 200);
  }

  // --- Modal nuevo proveedor ---

  abrirNuevoProveedor(): void {
    this.proveedorError = '';
    this.nuevoProveedor = this.proveedorVacio();
    this.showProveedorModal = true;
  }

  cerrarNuevoProveedor(): void {
    this.showProveedorModal = false;
  }

  guardarNuevoProveedor(): void {
    this.proveedorError = '';
    const p = this.nuevoProveedor;
    if (!p.nombre.trim() || !p.ruc.trim() || !p.email.trim() || !p.telefono.trim()) {
      this.proveedorError = 'Completa razon social, RUC, correo y telefono.';
      return;
    }

    this.guardandoProveedor = true;
    this.api.crearProveedor(p).subscribe({
      next: (res: any) => {
        this.guardandoProveedor = false;
        this.showProveedorModal = false;
        this.cargarProveedores(res?.datos || { ruc: p.ruc });
      },
      error: (err) => {
        this.guardandoProveedor = false;
        this.proveedorError = err?.error?.mensaje || err?.error?.message || 'No se pudo registrar el proveedor.';
        this.cdr.detectChanges();
      }
    });
  }

  // --- Producto dropdown ---

  abrirDropdownProducto(): void {
    this.productosFiltrados = [...this.productos];
    this.mostrarDropdownProducto = true;
  }

  filtrarProductos(): void {
    const q = this.busquedaProducto.toLowerCase();
    this.productosFiltrados = this.productos.filter(p =>
      (p.nombre || '').toLowerCase().includes(q) ||
      (p.marca || '').toLowerCase().includes(q) ||
      (p.modelo || '').toLowerCase().includes(q)
    );
    this.mostrarDropdownProducto = true;
    if (!this.busquedaProducto) {
      this.detalle.productoId = null;
      this.detalle.precioUnitario = 0;
    }
  }

  seleccionarProducto(p: any): void {
    this.detalle.productoId = p.id;
    this.busquedaProducto = p.nombre;
    this.mostrarDropdownProducto = false;
    this.productoCambiado();
    this.cdr.detectChanges();
  }

  cerrarDropdownProducto(): void {
    setTimeout(() => {
      this.mostrarDropdownProducto = false;
      this.cdr.detectChanges();
    }, 200);
  }

  // --- Detalle compra ---

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
    this.busquedaProducto = '';
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
