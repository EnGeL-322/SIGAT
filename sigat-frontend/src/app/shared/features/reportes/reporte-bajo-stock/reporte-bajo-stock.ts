import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';
import { escapeHtml } from '../../../utils/html-escape';

@Component({
  selector: 'app-reporte-bajo-stock',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './reporte-bajo-stock.html',
  styleUrl: './reporte-bajo-stock.css'
})
export class ReporteBajoStockComponent implements OnInit {
  productos: any[] = [];
  filtrados: any[] = [];
  fecha = new Date().toISOString().slice(0, 10);
  marca = '';
  modelo = '';
  estado = 'TODOS';
  itemsPorPagina = 10;
  paginaActual = 1;

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.api.obtenerProductos().subscribe((res: any) => {
      this.productos = (res?.datos || []).filter((item: any) => item.stockActual <= item.stockMinimo);
      this.filtrar();
      this.cdr.detectChanges();
    });
  }

  filtrar(): void {
    const marca = this.marca.toLowerCase().trim();
    const modelo = this.modelo.toLowerCase().trim();

    this.filtrados = this.productos.filter(item => {
      const estado = this.estadoProducto(item.stockActual);
      return (!marca || item.marca?.toLowerCase().includes(marca)) &&
        (!modelo || item.modelo?.toLowerCase().includes(modelo)) &&
        (this.estado === 'TODOS' || estado === this.estado);
    });
    this.paginaActual = 1;
  }

  get filtradosPaginados(): any[] {
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

  estadoProducto(stock: number): string {
    if (stock <= 0) return 'STOCK AGOTADO';
    if (stock <= 2) return 'STOCK MINIMO';
    return 'STOCK BAJO';
  }

  estadoClass(stock: number): string {
    if (stock <= 0) return 'danger';
    if (stock <= 2) return 'warning';
    return 'success';
  }

  exportarExcel(): void {
    const headers = ['Marca', 'Modelo', 'Codigo', 'Stock actual', 'Stock minimo', 'Estado'];
    const csv = [
      headers.join(';'),
      ...this.filtrados.map(item => [item.marca, item.modelo, item.codigo, item.stockActual, item.stockMinimo, this.estadoProducto(item.stockActual)].join(';'))
    ].join('\n');
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'reporte-bajo-stock.csv';
    link.click();
    URL.revokeObjectURL(link.href);
  }

  exportarPdf(): void {
    const rows = this.filtrados.map(item => `<tr><td>${escapeHtml(item.marca)}</td><td>${escapeHtml(item.modelo)}</td><td>${escapeHtml(item.codigo)}</td><td>${escapeHtml(item.stockActual)}</td><td>${escapeHtml(item.stockMinimo)}</td><td>${escapeHtml(this.estadoProducto(item.stockActual))}</td></tr>`).join('');
    const win = window.open('', '_blank');
    win?.document.write(`<html><head><title>Reporte de bajo stock</title><style>body{font-family:Arial;padding:24px}table{width:100%;border-collapse:collapse}th,td{border:1px solid #cbd5e1;padding:8px}th{background:#7d82ef;color:white}</style></head><body><h1>Reporte de bajo stock</h1><p>Fecha: ${escapeHtml(this.fecha)}</p><table><thead><tr><th>Marca</th><th>Modelo</th><th>Codigo</th><th>Stock actual</th><th>Stock minimo</th><th>Estado</th></tr></thead><tbody>${rows}</tbody></table></body></html>`);
    win?.document.close();
    win?.print();
  }
}
