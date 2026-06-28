import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { catchError, forkJoin, of } from 'rxjs';
import { ApiService } from '../../../../core/api.service';
import { escapeHtml } from '../../../utils/html-escape';

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
  filas: any[] = [];        // una fila por venta (lote)
  filtrados: any[] = [];
  selected: any = null;
  detailModal = false;
  loading = false;
  error = '';
  itemsPorPagina = 10;
  paginaActual = 1;

  fecha = '';
  clienteId: number | 'TODOS' = 'TODOS';
  productoId: number | 'TODOS' = 'TODOS';
  periodo: PeriodoReporte = 'DIA';

  // Buscador dentro del detalle de venta (filtra por IMEI o producto)
  busquedaImei = '';

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.loading = true;
    forkJoin({
      ventas: this.api.obtenerVentasConDetalles().pipe(catchError(() => of({ datos: [] }))),
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
      const coincideProducto = this.productoId === 'TODOS' ||
        fila.detalles.some((d: any) => d.productoId === this.productoId);
      return coincidePeriodo && coincideCliente && coincideProducto;
    });
    this.paginaActual = 1;
  }

  cambiarPeriodo(periodo: PeriodoReporte): void {
    this.periodo = periodo;
    this.filtrar();
  }

  totalVendido(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.total || 0), 0);
  }

  cantidadEquipos(): number {
    return this.filtrados.reduce((total, fila) => total + Number(fila.cantidadEquipos || 0), 0);
  }

  numeroVentas(): number {
    return this.filtrados.length;
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

  /** Equipos vendidos de la venta seleccionada, filtrados por el buscador de IMEI/producto. */
  get equiposDetalle(): any[] {
    const equipos = (this.selected?.detalles || []).map((d: any) => ({
      productoNombre: d.productoNombre,
      imeiNumero: d.imeiNumero || 'Automatico',
      precioUnitario: d.precioUnitario,
      estado: 'VENDIDO'
    }));

    const q = this.busquedaImei.trim().toLowerCase();
    if (!q) return equipos;
    return equipos.filter((e: any) =>
      (e.imeiNumero || '').toLowerCase().includes(q) ||
      (e.productoNombre || '').toLowerCase().includes(q)
    );
  }

  imprimirFila(fila: any): void {
    this.imprimirReporte('Detalle de venta', [fila]);
  }

  exportarExcel(): void {
    const rows = this.filtrados.map(fila => [
      fila.codigoVenta,
      this.formatearFecha(fila.fechaVenta),
      fila.clienteNombre,
      fila.cantidadEquipos,
      fila.total,
      (fila.detalles || []).map((d: any) => d.imeiNumero).filter(Boolean).join(', ')
    ]);
    this.descargarExcel('reporte-ventas.xls', rows);
  }

  exportarPdf(): void {
    this.imprimirReporte('Reporte de ventas', this.filtrados);
  }

  /** El backend ya devuelve venta + detalles en una sola respuesta (sin N+1). */
  private cargarDetalles(): void {
    this.filas = this.ventas.map((item: any) => {
      const venta = item.venta || {};
      const detalles = item.detalles || [];
      return {
        id: venta.id,
        codigoVenta: venta.numeroVenta,
        fechaVenta: venta.fechaVenta,
        clienteId: venta.clienteId,
        clienteNombre: venta.clienteNombre,
        vendedorNombre: venta.vendedorNombre || 'SIGAT',
        estado: venta.estado,
        total: venta.total ?? detalles.reduce((s: number, d: any) => s + Number(d.subtotal || d.precioUnitario || 0), 0),
        detalles,
        cantidadEquipos: detalles.length
      };
    });
    this.filtrar();
    this.loading = false;
    this.cdr.detectChanges();
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

  private descargarExcel(nombre: string, rows: any[][]): void {
    const htmlRows = rows.map(row => `<tr>${row.map(col => `<td>${escapeHtml(col)}</td>`).join('')}</tr>`).join('');
    const html = `
      <table>
        <thead><tr><th>Codigo venta</th><th>Fecha</th><th>Cliente</th><th>Equipos</th><th>Total</th><th>IMEI</th></tr></thead>
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
        <td>${escapeHtml(fila.codigoVenta)}</td>
        <td>${escapeHtml(this.formatearFecha(fila.fechaVenta))}</td>
        <td>${escapeHtml(fila.clienteNombre)}</td>
        <td>${escapeHtml(fila.cantidadEquipos)}</td>
        <td>S/ ${Number(fila.total || 0).toFixed(2)}</td>
        <td>${escapeHtml((fila.detalles || []).map((d: any) => d.imeiNumero).filter(Boolean).join(', '))}</td>
      </tr>
    `).join('');
    const win = window.open('', '_blank');
    win?.document.write(`
      <html><head><title>${escapeHtml(titulo)}</title><style>
        body{font-family:Arial,sans-serif;padding:24px;color:#1f2937}
        table{width:100%;border-collapse:collapse} th,td{border:1px solid #cbd5e1;padding:8px;text-align:left}
        th{background:#7d82ef;color:white}
      </style></head><body>
      <h1>${escapeHtml(titulo)}</h1>
      <p>Fecha base: ${escapeHtml(this.fecha || 'Todas')}</p>
      <p>Total vendido: S/ ${total.toFixed(2)}</p>
      <table><thead><tr><th>Codigo venta</th><th>Fecha</th><th>Cliente</th><th>Equipos</th><th>Total</th><th>IMEI</th></tr></thead><tbody>${htmlRows}</tbody></table>
      </body></html>
    `);
    win?.document.close();
    win?.print();
  }
}
