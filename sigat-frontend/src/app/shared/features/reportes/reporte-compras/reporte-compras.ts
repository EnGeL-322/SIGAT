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
  filas: any[] = [];        // una fila por compra (lote)
  filtrados: any[] = [];
  selected: any = null;
  detailModal = false;
  loading = false;
  itemsPorPagina = 10;
  paginaActual = 1;

  fecha = '';
  proveedorId: number | 'TODOS' = 'TODOS';
  productoId: number | 'TODOS' = 'TODOS';
  periodo: PeriodoReporte = 'DIA';

  // Buscador dentro del detalle de compra (filtra por IMEI o producto)
  busquedaImei = '';

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
      const coincideProducto = this.productoId === 'TODOS' ||
        fila.detalles.some((d: any) => d.productoId === this.productoId);
      return coincidePeriodo && coincideProveedor && coincideProducto;
    });
    this.paginaActual = 1;
  }

  cambiarPeriodo(periodo: PeriodoReporte): void {
    this.periodo = periodo;
    this.filtrar();
  }

  totalComprado(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.total || 0), 0);
  }

  cantidadEquipos(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.cantidadEquipos || 0), 0);
  }

  numeroCompras(): number {
    return this.filtrados.length;
  }

  totalImeis(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.totalImeis || 0), 0);
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
    this.busquedaImei = '';
    this.detailModal = true;
  }

  /** Equipos (IMEIs) de la compra seleccionada, filtrados por el buscador de IMEI/producto. */
  get equiposDetalle(): any[] {
    const equipos = (this.selected?.detalles || []).flatMap((d: any) =>
      (d.imeis || []).map((imei: any) => ({
        productoNombre: d.productoNombre,
        imeiNumero: imei.numero,
        estado: imei.estado,
        precioUnitario: d.precioUnitario
      }))
    );

    const q = this.busquedaImei.trim().toLowerCase();
    if (!q) return equipos;
    return equipos.filter((e: any) =>
      (e.imeiNumero || '').toLowerCase().includes(q) ||
      (e.productoNombre || '').toLowerCase().includes(q)
    );
  }

  imprimirFila(fila: any): void {
    this.imprimirReporte('Detalle de compra', [fila]);
  }

  exportarExcel(): void {
    const rows = this.filtrados.map(fila => [
      fila.codigoCompra,
      this.formatearFecha(fila.fechaCompra),
      fila.proveedorNombre,
      fila.cantidadEquipos,
      fila.total,
      (fila.detalles || []).flatMap((d: any) => (d.imeis || []).map((i: any) => i.numero)).join(', ')
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
        map((res: any) => {
          const detalles = res?.datos || [];
          return {
            id: compra.id,
            codigoCompra: compra.numeroCompra,
            fechaCompra: compra.fechaCompra,
            proveedorId: compra.proveedorId,
            proveedorNombre: compra.proveedorNombre,
            estadoCompra: compra.estado,
            total: compra.total ?? detalles.reduce((s: number, d: any) => s + Number(d.subtotal || 0), 0),
            detalles,
            cantidadEquipos: detalles.reduce((s: number, d: any) => s + Number(d.cantidad || 0), 0),
            totalImeis: detalles.reduce((s: number, d: any) => s + (d.imeis?.length || 0), 0)
          };
        }),
        catchError(() => of(null))
      )
    );

    forkJoin(requests).subscribe((filas: any[]) => {
      this.filas = filas.filter(Boolean);
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
        <thead><tr><th>Codigo compra</th><th>Fecha</th><th>Proveedor</th><th>Equipos</th><th>Total</th><th>IMEI</th></tr></thead>
        <tbody>${htmlRows}</tbody>
      </table>
    `;
    const blob = new Blob(['﻿' + html], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = nombre;
    link.click();
    URL.revokeObjectURL(link.href);
  }

  private imprimirReporte(titulo: string, filas: any[]): void {
    const total = filas.reduce((sum, fila) => sum + Number(fila.total || 0), 0);
    const htmlRows = filas.map(fila => `
      <tr>
        <td>${fila.codigoCompra ?? ''}</td>
        <td>${this.formatearFecha(fila.fechaCompra)}</td>
        <td>${fila.proveedorNombre ?? ''}</td>
        <td>${fila.cantidadEquipos ?? ''}</td>
        <td>S/ ${Number(fila.total || 0).toFixed(2)}</td>
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
      <p>Fecha base: ${this.fecha || 'Todas'}</p>
      <p>Total comprado: S/ ${total.toFixed(2)}</p>
      <table><thead><tr><th>Codigo compra</th><th>Fecha</th><th>Proveedor</th><th>Equipos</th><th>Total</th></tr></thead><tbody>${htmlRows}</tbody></table>
      </body></html>
    `);
    win?.document.close();
    win?.print();
  }
}
