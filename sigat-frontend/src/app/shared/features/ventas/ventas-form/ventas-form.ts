import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';
import { AuthService } from '../../../../core/auth.service';

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
  imeisDisponibles: any[] = [];
  detalles: any[] = [];
  error = '';
  vendedorNombre = '';
  vendedorId: number | null = null;

  busquedaCliente = '';
  mostrarDropdownCliente = false;
  clientesFiltrados: any[] = [];

  usuarios: any[] = [];
  busquedaVendedor = '';
  mostrarDropdownVendedor = false;
  vendedoresFiltrados: any[] = [];

  busquedaProducto = '';
  mostrarDropdownProducto = false;
  productosFiltrados: any[] = [];

  showClienteModal = false;
  guardandoCliente = false;
  clienteError = '';
  nuevoCliente = this.clienteVacio();

  // Scanner
  showScannerModal = false;
  scannerMode: 'camera' | 'usb' = 'camera';
  scannerInput = '';
  scannerLoading = false;
  scannerError = '';
  scannerResult: any = null;
  private _scanStream: MediaStream | null = null;
  private _scanInterval: ReturnType<typeof setInterval> | null = null;

  venta = {
    clienteId: null as number | null,
    fecha: new Date().toISOString().slice(0, 10),
    tipoComprobante: '',
    dni: '',
    vendedor: 'SIGAT'
  };

  detalle = {
    productoId: null as number | null,
    imeiId: null as number | null,
    cantidad: 1,
    precioUnitario: 0
  };

  constructor(
    private api: ApiService,
    private auth: AuthService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const user = this.auth.getUser();
    this.vendedorId = user?.usuarioId ?? null;
    this.vendedorNombre = [user?.nombre, user?.apellido].filter(Boolean).join(' ') || user?.nombre || 'SIGAT';
    this.venta.vendedor = this.vendedorNombre;
    this.busquedaVendedor = this.vendedorNombre;

    this.cargarClientes();
    this.api.obtenerProductos().subscribe((r: any) => {
      this.productos = r?.datos || [];
      this.cdr.detectChanges();
    });
    this.api.obtenerUsuarios().subscribe((r: any) => {
      this.usuarios = r?.datos || [];
      this.cdr.detectChanges();
    });
  }

  private clienteVacio() {
    return { nombre: '', apellido: '', cedula: '', email: '', telefono: '', direccion: '' };
  }

  cargarClientes(seleccionar?: any): void {
    this.api.obtenerClientes().subscribe((r: any) => {
      this.clientes = r?.datos || [];
      if (seleccionar) {
        const match = this.clientes.find(c =>
          (seleccionar.id != null && c.id === seleccionar.id) ||
          (seleccionar.cedula && c.cedula === seleccionar.cedula));
        if (match) {
          this.venta.clienteId = match.id;
          this.busquedaCliente = `${match.nombre} ${match.apellido}`;
          this.clienteCambiado();
        }
      }
      this.cdr.detectChanges();
    });
  }

  clienteCambiado(): void {
    const cliente = this.clientes.find(c => c.id == this.venta.clienteId);
    this.venta.dni = cliente?.cedula || '';
  }

  // --- Cliente dropdown ---

  abrirDropdownCliente(): void {
    this.clientesFiltrados = [...this.clientes];
    this.mostrarDropdownCliente = true;
  }

  filtrarClientes(): void {
    const q = this.busquedaCliente.toLowerCase();
    this.clientesFiltrados = this.clientes.filter(c =>
      `${c.nombre} ${c.apellido}`.toLowerCase().includes(q) ||
      (c.cedula || '').toLowerCase().includes(q)
    );
    this.mostrarDropdownCliente = true;
    if (!this.busquedaCliente) {
      this.venta.clienteId = null;
      this.venta.dni = '';
    }
  }

  seleccionarCliente(c: any): void {
    this.venta.clienteId = c.id;
    this.busquedaCliente = `${c.nombre} ${c.apellido}`;
    this.mostrarDropdownCliente = false;
    this.clienteCambiado();
    this.cdr.detectChanges();
  }

  cerrarDropdownCliente(): void {
    setTimeout(() => {
      this.mostrarDropdownCliente = false;
      this.cdr.detectChanges();
    }, 200);
  }

  // --- Vendedor dropdown ---

  abrirDropdownVendedor(): void {
    this.vendedoresFiltrados = [...this.usuarios];
    this.mostrarDropdownVendedor = true;
  }

  filtrarVendedores(): void {
    const q = this.busquedaVendedor.toLowerCase();
    this.vendedoresFiltrados = this.usuarios.filter(u =>
      `${u.nombre || ''} ${u.apellido || ''}`.toLowerCase().includes(q) ||
      (u.email || '').toLowerCase().includes(q)
    );
    this.mostrarDropdownVendedor = true;
  }

  seleccionarVendedor(u: any): void {
    this.vendedorId = u.id ?? u.usuarioId ?? null;
    this.vendedorNombre = [u.nombre, u.apellido].filter(Boolean).join(' ') || u.email || 'SIGAT';
    this.busquedaVendedor = this.vendedorNombre;
    this.venta.vendedor = this.vendedorNombre;
    this.mostrarDropdownVendedor = false;
    this.cdr.detectChanges();
  }

  cerrarDropdownVendedor(): void {
    setTimeout(() => {
      this.mostrarDropdownVendedor = false;
      this.cdr.detectChanges();
    }, 200);
  }

  // --- Modal nuevo cliente ---

  abrirNuevoCliente(): void {
    this.clienteError = '';
    this.nuevoCliente = this.clienteVacio();
    this.showClienteModal = true;
  }

  cerrarNuevoCliente(): void {
    this.showClienteModal = false;
  }

  guardarNuevoCliente(): void {
    this.clienteError = '';
    const c = this.nuevoCliente;
    if (!c.nombre.trim() || !c.apellido.trim() || !c.cedula.trim() || !c.email.trim() || !c.telefono.trim()) {
      this.clienteError = 'Completa nombre, apellido, cedula, correo y telefono.';
      return;
    }

    this.guardandoCliente = true;
    this.api.crearCliente(c).subscribe({
      next: (res: any) => {
        this.guardandoCliente = false;
        this.showClienteModal = false;
        this.cargarClientes(res?.datos || { cedula: c.cedula });
      },
      error: (err) => {
        this.guardandoCliente = false;
        this.clienteError = err?.error?.mensaje || err?.error?.message || 'No se pudo registrar el cliente.';
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
      this.imeisDisponibles = [];
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

  // --- Detalle venta ---

  productoCambiado(): void {
    const producto = this.productos.find(p => p.id == this.detalle.productoId);
    this.detalle.imeiId = null;
    this.imeisDisponibles = [];

    if (producto?.precio !== undefined) {
      this.detalle.precioUnitario = Number(producto.precio || 0);
    }

    if (!this.detalle.productoId) {
      this.cdr.detectChanges();
      return;
    }

    this.api.obtenerIMEIPorProducto(this.detalle.productoId).subscribe((res: any) => {
      this.imeisDisponibles = (res?.datos || []).filter((imei: any) => imei.estado === 'EN_STOCK');
      this.cdr.detectChanges();
    });
  }

  imeiCambiado(): void {
    if (this.detalle.imeiId) {
      this.detalle.cantidad = 1;
    }
  }

  agregarDetalle(): void {
    this.error = '';
    if (!this.detalle.productoId || !this.detalle.cantidad || !this.detalle.precioUnitario) return;

    const producto = this.productos.find(p => p.id == this.detalle.productoId);
    const imei = this.imeisDisponibles.find(item => item.id == this.detalle.imeiId);

    if (this.detalle.imeiId && !imei) {
      this.error = 'Selecciona un IMEI disponible para este producto.';
      return;
    }

    if (producto?.stockActual !== undefined && this.detalle.cantidad > producto.stockActual) {
      this.error = `Stock insuficiente. Disponible: ${producto.stockActual}`;
      return;
    }

    this.detalles.push({
      productoId: this.detalle.productoId,
      productoNombre: producto?.nombre,
      imeiId: this.detalle.imeiId,
      imeiNumero: imei?.numero,
      cantidad: this.detalle.cantidad,
      precioUnitario: this.detalle.precioUnitario,
      subtotal: this.detalle.cantidad * this.detalle.precioUnitario
    });

    this.detalle = {
      productoId: null,
      imeiId: null,
      cantidad: 1,
      precioUnitario: 0
    };
    this.busquedaProducto = '';
    this.imeisDisponibles = [];
  }

  eliminarDetalle(index: number): void {
    this.detalles.splice(index, 1);
  }

  // --- Scanner IMEI ---

  abrirScanner(): void {
    this.showScannerModal = true;
    this.scannerMode = 'camera';
    this.scannerInput = '';
    this.scannerError = '';
    this.scannerResult = null;
    this.cdr.detectChanges();
    setTimeout(() => this.iniciarCamara(), 300);
  }

  cerrarScanner(): void {
    this.detenerCamara();
    this.showScannerModal = false;
    this.cdr.detectChanges();
  }

  cambiarModoScanner(mode: 'camera' | 'usb'): void {
    this.detenerCamara();
    this.scannerMode = mode;
    this.scannerError = '';
    this.scannerResult = null;
    this.cdr.detectChanges();
    if (mode === 'camera') {
      setTimeout(() => this.iniciarCamara(), 300);
    }
  }

  async iniciarCamara(): Promise<void> {
    if (typeof (window as any).BarcodeDetector === 'undefined') {
      this.scannerError = 'Tu navegador no soporta escaneo por camara. Usa Chrome/Edge o cambia a Lector USB.';
      this.scannerMode = 'usb';
      this.cdr.detectChanges();
      return;
    }
    try {
      this._scanStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      const video = document.getElementById('imei-scanner-video') as HTMLVideoElement;
      if (!video) return;
      video.srcObject = this._scanStream;
      await video.play();

      const detector = new (window as any).BarcodeDetector({
        formats: ['code_128', 'ean_13', 'ean_8', 'qr_code', 'upc_a', 'upc_e', 'code_39', 'code_93']
      });

      this._scanInterval = setInterval(async () => {
        if (!video || video.readyState < 2 || this.scannerLoading || this.scannerResult) return;
        try {
          const barcodes = await detector.detect(video);
          if (barcodes.length > 0) {
            this.detenerCamara();
            this.buscarIMEI(barcodes[0].rawValue);
          }
        } catch (_) { /* ignored */ }
      }, 500);

      this.cdr.detectChanges();
    } catch (err: any) {
      this.scannerError = 'No se pudo acceder a la camara. ' + (err?.message || 'Verifica los permisos.') + ' Usa el Lector USB.';
      this.scannerMode = 'usb';
      this.cdr.detectChanges();
    }
  }

  detenerCamara(): void {
    if (this._scanInterval) { clearInterval(this._scanInterval); this._scanInterval = null; }
    if (this._scanStream) { this._scanStream.getTracks().forEach(t => t.stop()); this._scanStream = null; }
  }

  onScannerKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter') {
      const val = this.scannerInput.trim();
      if (val) this.buscarIMEI(val);
    }
  }

  buscarIMEI(numero: string): void {
    this.scannerLoading = true;
    this.scannerError = '';
    this.scannerResult = null;
    this.cdr.detectChanges();

    this.api.obtenerIMEIPorNumero(numero).subscribe({
      next: (res: any) => {
        const data = res?.datos;
        if (!data) {
          this.scannerError = 'Producto no encontrado para ese codigo.';
        } else {
          this.scannerResult = data;
        }
        this.scannerLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.scannerError = 'Producto no encontrado para ese codigo.';
        this.scannerLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  usarIMEIEscaneado(): void {
    const imei = this.scannerResult;
    if (!imei) return;

    const producto = this.productos.find((p: any) => p.id === imei.productoId);
    if (producto) {
      this.detalle.productoId = producto.id;
      this.busquedaProducto = producto.nombre;
      this.detalle.precioUnitario = Number(producto.precio || 0);
      this.imeisDisponibles = [];

      this.api.obtenerIMEIPorProducto(imei.productoId).subscribe((r: any) => {
        this.imeisDisponibles = (r?.datos || []).filter((i: any) => i.estado === 'EN_STOCK');
        if (imei.estado === 'EN_STOCK') {
          this.detalle.imeiId = imei.id;
          this.detalle.cantidad = 1;
        }
        this.cdr.detectChanges();
      });
    }

    this.cerrarScanner();
  }

  escanearNuevo(): void {
    this.scannerResult = null;
    this.scannerError = '';
    this.scannerInput = '';
    this.cdr.detectChanges();
    if (this.scannerMode === 'camera') {
      setTimeout(() => this.iniciarCamara(), 300);
    }
  }

  get previewNumeroVenta(): string {
    switch (this.venta.tipoComprobante) {
      case 'BOLETA':  return 'B001-XXXXXX';
      case 'FACTURA': return 'F001-XXXXXX';
      default: return '';
    }
  }

  guardar(): void {
    this.error = '';
    if (!this.venta.clienteId || this.detalles.length === 0) return;

    const payload = {
      venta: {
        clienteId: this.venta.clienteId,
        vendedorId: this.vendedorId,
        vendedorNombre: this.vendedorNombre,
        tipoComprobante: this.venta.tipoComprobante || null
      },
      detalles: this.detalles.map(d => ({
        productoId: d.productoId,
        imeiId: d.imeiId,
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

  get productoSeleccionado(): any {
    return this.productos.find(p => p.id == this.detalle.productoId) || null;
  }

  get stockDisponible(): number | null {
    const producto = this.productoSeleccionado;
    if (!producto) return null;
    return producto.stockActual ?? 0;
  }
}
