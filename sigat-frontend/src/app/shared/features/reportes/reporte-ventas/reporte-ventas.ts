import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { catchError, forkJoin, map, of } from 'rxjs';
import { ApiService } from '../../../../core/api.service';

type PeriodoReporte = 'DIA' | 'SEMANA' | 'MES';

@Component({
  selector: 'app-reporte-ventas',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './reporte-ventas.html',
  styleUrl: './reporte-ventas.css'
})
export class ReporteVentasComponent implements OnInit {
  ventas: any[] = [];
  clientes: any[] = [];
  productos: any[] = [];
  filas: any[] = [];
  filtrados: any[] = [];
  selected: any = null;
  detailModal = false;

  fecha = '';
  clienteId: number | 'TODOS' = 'TODOS';
  productoId: number | 'TODOS' = 'TODOS';
  periodo: PeriodoReporte = 'DIA';

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    forkJoin({
      ventas: this.api.obtenerVentas().pipe(catchError(() => of({ datos: [] }))),
      clientes: this.api.obtenerClientes().pipe(catchError(() => of({ datos: [] }))),
      productos: this.api.obtenerProductos().pipe(catchError(() => of({ datos: [] })))
    }).subscribe((res: any) => {
      this.ventas = res.ventas?.datos || [];
      this.clientes = res.clientes?.datos || [];
      this.productos = res.productos?.datos || [];
      this.cargarDetalles();
    });
  }

  filtrar(): void {
    this.filtrados = this.filas.filter(fila => {
      const coincidePeriodo = this.estaEnPeriodo(fila.fechaVenta);
      const coincideCliente = this.clienteId === 'TODOS' || fila.clienteId === this.clienteId;
      const coincideProducto = this.productoId === 'TODOS' || fila.productoId === this.productoId;
      return coincidePeriodo && coincideCliente && coincideProducto;
    });
  }

  cambiarPeriodo(periodo: PeriodoReporte): void {
    this.periodo = periodo;
    this.filtrar();
  }

  totalVendido(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.precioUnitario || fila.subtotal || 0), 0);
  }

  cantidadEquipos(): number {
    return this.filtrados.length;
  }

  numeroVentas(): number {
    return new Set(this.filtrados.map(fila => fila.ventaId)).size;
  }

  verDetalle(fila: any): void {
    this.selected = fila;
    this.detailModal = true;
  }

  imprimirFila(fila: any): void {
    this.imprimirReporte('Detalle de venta', [fila]);
  }

  exportarExcel(): void {
    const rows = this.filtrados.map(fila => ({
      CodigoVenta: fila.codigoVenta,
      Fecha: this.formatearFecha(fila.fechaVenta),
      Cliente: fila.clienteNombre,
      Producto: fila.productoNombre,
      IMEI: fila.imeiNumero,
      Precio: fila.precioUnitario
    }));
    this.descargarCsv('reporte-ventas.csv', rows);
  }

  exportarPdf(): void {
    this.imprimirReporte('Reporte de ventas', this.filtrados);
  }

  private cargarDetalles(): void {
    if (!this.ventas.length) {
      this.filas = [];
      this.filtrar();
      this.cdr.detectChanges();
      return;
    }

    const requests = this.ventas.map(venta =>
      this.api.obtenerDetallesVenta(venta.id).pipe(
        map((res: any) => (res?.datos || []).map((detalle: any) => ({
          ...detalle,
          ventaId: venta.id,
          codigoVenta: venta.numeroVenta,
          fechaVenta: venta.fechaVenta,
          clienteId: venta.clienteId,
          clienteNombre: venta.clienteNombre
        }))),
        catchError(() => of([]))
      )
    );

    forkJoin(requests).subscribe((grupos: any[]) => {
      this.filas = grupos.flat();
      this.filtrar();
      this.cdr.detectChanges();
    });
  }

  private estaEnPeriodo(fechaVenta: string): boolean {
    if (!this.fecha || !fechaVenta) return true;

    const base = this.normalizarFecha(this.fecha);
    const target = this.normalizarFecha(fechaVenta);
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

  private descargarCsv(nombre: string, rows: any[]): void {
    const headers = Object.keys(rows[0] || { Reporte: '' });
    const csv = [headers.join(';'), ...rows.map(row => headers.map(header => row[header] ?? '').join(';'))].join('\n');
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = nombre;
    link.click();
    URL.revokeObjectURL(link.href);
  }

  private imprimirReporte(titulo: string, rows: any[]): void {
    const htmlRows = rows.map(fila => `
      <tr>
        <td>${fila.codigoVenta ?? ''}</td>
        <td>${this.formatearFecha(fila.fechaVenta)}</td>
        <td>${fila.clienteNombre ?? ''}</td>
        <td>${fila.productoNombre ?? ''}</td>
        <td>${fila.imeiNumero ?? ''}</td>
        <td>${fila.precioUnitario ?? ''}</td>
      </tr>
    `).join('');
    const win = window.open('', '_blank');
    win?.document.write(`
      <html><head><title>${titulo}</title><style>
        body{font-family:Arial,sans-serif;padding:24px;color:#1f2937}
        table{width:100%;border-collapse:collapse} th,td{border:1px solid #cbd5e1;padding:8px;text-align:left}
        th{background:#7d82ef;color:white}
      </style></head><body>
      <h1>${titulo}</h1>
      <p>Fecha base: ${this.fecha}</p>
      <p>Total vendido: S/ ${this.totalVendido().toFixed(2)}</p>
      <table><thead><tr><th>Codigo venta</th><th>Fecha</th><th>Cliente</th><th>Producto</th><th>IMEI</th><th>Precio</th></tr></thead><tbody>${htmlRows}</tbody></table>
      </body></html>
    `);
    win?.document.close();
    win?.print();
  }
}
