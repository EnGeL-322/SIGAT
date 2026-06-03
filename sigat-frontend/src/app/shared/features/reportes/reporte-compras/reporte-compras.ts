import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { catchError, forkJoin, map, of } from 'rxjs';
import { ApiService } from '../../../../core/api.service';

type PeriodoReporte = 'DIA' | 'SEMANA' | 'MES';

@Component({
  selector: 'app-reporte-compras',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './reporte-compras.html',
  styleUrl: './reporte-compras.css'
})
export class ReporteComprasComponent implements OnInit {
  compras: any[] = [];
  proveedores: any[] = [];
  productos: any[] = [];
  filas: any[] = [];
  filtrados: any[] = [];
  selected: any = null;
  detailModal = false;
  imeiModal = false;
  loading = false;
  itemsPorPagina = 10;
  paginaActual = 1;

  fecha = '';
  proveedorId: number | 'TODOS' = 'TODOS';
  productoId: number | 'TODOS' = 'TODOS';
  periodo: PeriodoReporte = 'DIA';

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.loading = true;
    forkJoin({
      compras: this.api.obtenerCompras().pipe(catchError(() => of({ datos: [] }))),
      proveedores: this.api.obtenerProveedores().pipe(catchError(() => of({ datos: [] }))),
      productos: this.api.obtenerProductos().pipe(catchError(() => of({ datos: [] })))
    }).subscribe((res: any) => {
      this.compras = res.compras?.datos || [];
      this.proveedores = res.proveedores?.datos || [];
      this.productos = res.productos?.datos || [];
      this.cargarDetalles();
    });
  }

  filtrar(): void {
    this.filtrados = this.filas.filter(fila => {
      const coincidePeriodo = this.estaEnPeriodo(fila.fechaCompra);
      const coincideProveedor = this.proveedorId === 'TODOS' || fila.proveedorId === this.proveedorId;
      const coincideProducto = this.productoId === 'TODOS' || fila.productoId === this.productoId;
      return coincidePeriodo && coincideProveedor && coincideProducto;
    });
    this.paginaActual = 1;
  }

  cambiarPeriodo(periodo: PeriodoReporte): void {
    this.periodo = periodo;
    this.filtrar();
  }

  totalComprado(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.subtotal || 0), 0);
  }

  cantidadEquipos(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.cantidad || 0), 0);
  }

  numeroCompras(): number {
    return new Set(this.filtrados.map(fila => fila.compraId)).size;
  }

  totalImeis(): number {
    return this.filtrados.reduce((total, fila) => total + (fila.imeis?.length || 0), 0);
  }

  get filasPaginadas(): any[] {
    const inicio = (this.paginaActual - 1) * this.itemsPorPagina;
    return this.filtrados.slice(inicio, inicio + this.itemsPorPagina);
  }

  get totalPaginas(): number {
    return Math.max(1, Math.ceil(this.filtrados.length / this.itemsPorPagina));
  }

  get paginas(): number[] {
    return Array.from({ length: this.totalPaginas }, (_, index) => index + 1);
  }

  get inicioPagina(): number {
    if (!this.filtrados.length) return 0;
    return (this.paginaActual - 1) * this.itemsPorPagina + 1;
  }

  get finPagina(): number {
    return Math.min(this.paginaActual * this.itemsPorPagina, this.filtrados.length);
  }

  cambiarPagina(pagina: number): void {
    if (pagina < 1 || pagina > this.totalPaginas) return;
    this.paginaActual = pagina;
  }

  verDetalle(fila: any): void {
    this.selected = fila;
    this.detailModal = true;
  }

  verImeis(fila: any): void {
    this.selected = fila;
    this.imeiModal = true;
  }

  imprimirFila(fila: any): void {
    this.imprimirReporte('Detalle de compra', [fila]);
  }

  exportarExcel(): void {
    const rows = this.filtrados.map(fila => [
      fila.codigoCompra,
      this.formatearFecha(fila.fechaCompra),
      fila.proveedorNombre,
      fila.productoNombre,
      fila.cantidad,
      fila.subtotal,
      (fila.imeis || []).map((imei: any) => imei.numero).join(', ')
    ]);
    this.descargarExcel('reporte-compras.xls', rows);
  }

  exportarPdf(): void {
    this.imprimirReporte('Reporte de compras', this.filtrados);
  }

  private cargarDetalles(): void {
    if (!this.compras.length) {
      this.filas = [];
      this.filtrar();
      this.loading = false;
      this.cdr.detectChanges();
      return;
    }

    const requests = this.compras.map(compra =>
      this.api.obtenerDetallesCompra(compra.id).pipe(
        map((res: any) => (res?.datos || []).map((detalle: any) => ({
          ...detalle,
          compraId: compra.id,
          codigoCompra: compra.numeroCompra,
          fechaCompra: compra.fechaCompra,
          proveedorId: compra.proveedorId,
          proveedorNombre: compra.proveedorNombre,
          estadoCompra: compra.estado
        }))),
        catchError(() => of([]))
      )
    );

    forkJoin(requests).subscribe((grupos: any[]) => {
      this.filas = grupos.flat();
      this.filtrar();
      this.loading = false;
      this.cdr.detectChanges();
    });
  }

  private estaEnPeriodo(fechaCompra: string): boolean {
    if (!this.fecha || !fechaCompra) return true;

    const base = this.normalizarFecha(this.fecha);
    const target = this.normalizarFecha(fechaCompra);
    if (!base || !target) return false;

    if (this.periodo === 'DIA') {
      return target.toDateString() === base.toDateString();
    }

    if (this.periodo === 'SEMANA') {
      const inicio = this.inicioSemana(base);
      const fin = new Date(inicio);
      fin.setDate(inicio.getDate() + 6);
      fin.setHours(23, 59, 59, 999);
      return target >= inicio && target <= fin;
    }

    return target.getFullYear() === base.getFullYear() && target.getMonth() === base.getMonth();
  }

  private normalizarFecha(value: string): Date | null {
    const date = value.includes('T') ? new Date(value) : new Date(`${value}T00:00:00`);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  private inicioSemana(date: Date): Date {
    const inicio = new Date(date);
    const dia = inicio.getDay();
    const desplazamiento = dia === 0 ? -6 : 1 - dia;
    inicio.setDate(inicio.getDate() + desplazamiento);
    inicio.setHours(0, 0, 0, 0);
    return inicio;
  }

  private formatearFecha(value: string): string {
    const date = this.normalizarFecha(value);
    return date ? date.toLocaleDateString('es-PE') : '';
  }

  private descargarExcel(nombre: string, rows: any[][]): void {
    const htmlRows = rows.map(row => `<tr>${row.map(col => `<td>${col ?? ''}</td>`).join('')}</tr>`).join('');
    const html = `
      <table>
        <thead><tr><th>Codigo compra</th><th>Fecha</th><th>Proveedor</th><th>Producto</th><th>Total equipos</th><th>Total</th><th>IMEI</th></tr></thead>
        <tbody>${htmlRows}</tbody>
      </table>
    `;
    const blob = new Blob(['\ufeff' + html], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = nombre;
    link.click();
    URL.revokeObjectURL(link.href);
  }

  private imprimirReporte(titulo: string, rows: any[]): void {
    const total = rows.reduce((sum, fila) => sum + Number(fila.subtotal || 0), 0);
    const htmlRows = rows.map(fila => `
      <tr>
        <td>${fila.codigoCompra ?? ''}</td>
        <td>${this.formatearFecha(fila.fechaCompra)}</td>
        <td>${fila.proveedorNombre ?? ''}</td>
        <td>${fila.productoNombre ?? ''}</td>
        <td>${fila.cantidad ?? ''}</td>
        <td>${fila.subtotal ?? ''}</td>
      </tr>
    `).join('');
    const win = window.open('', '_blank');
    win?.document.write(`
      <html><head><title>${titulo}</title><style>
        body{font-family:Arial,sans-serif;padding:24px;color:#1f2937}
        table{width:100%;border-collapse:collapse} th,td{border:1px solid #cbd5e1;padding:8px;text-align:left}
        th{background:#315cb6;color:white}
      </style></head><body>
      <h1>${titulo}</h1>
      <p>Fecha base: ${this.fecha}</p>
      <p>Total comprado: S/ ${total.toFixed(2)}</p>
      <table><thead><tr><th>Codigo compra</th><th>Fecha</th><th>Proveedor</th><th>Producto</th><th>Total equipos</th><th>Total</th></tr></thead><tbody>${htmlRows}</tbody></table>
      </body></html>
    `);
    win?.document.close();
    win?.print();
  }
}
