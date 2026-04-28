import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-reporte-stock',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './reporte-stock.html',
  styleUrl: './reporte-stock.css'
})
export class ReporteStockComponent implements OnInit {
  productos: any[] = [];
  filtrados: any[] = [];
  fecha = new Date().toISOString().slice(0, 10);
  marca = '';
  modelo = '';
  estado = 'TODOS';

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.api.obtenerProductos().subscribe((res: any) => {
      this.productos = res?.datos || [];
      this.filtrar();
      this.cdr.detectChanges();
    });
  }

  filtrar(): void {
    const marca = this.marca.toLowerCase().trim();
    const modelo = this.modelo.toLowerCase().trim();

    this.filtrados = this.productos.filter(item => {
      const coincideMarca = !marca || item.marca?.toLowerCase().includes(marca);
      const coincideModelo = !modelo || item.modelo?.toLowerCase().includes(modelo);
      const coincideEstado = this.estado === 'TODOS' || this.estadoProducto(item.stockActual, item.stockMinimo) === this.estado;
      return coincideMarca && coincideModelo && coincideEstado;
    });
  }

  estadoProducto(stock: number, minimo: number): string {
    if (stock <= 0) return 'AGOTADO';
    if (stock <= minimo) return 'STOCK BAJO';
    return 'DISPONIBLE';
  }

  estadoClass(stock: number, minimo: number): string {
    if (stock <= 0) return 'danger';
    if (stock <= minimo) return 'warning';
    return 'success';
  }

  totalStock(): number {
    return this.filtrados.reduce((total, item) => total + (item.stockActual || 0), 0);
  }

  exportarExcel(): void {
    const rows = this.filtrados.map(item => ({
      Marca: item.marca,
      Modelo: item.modelo,
      Codigo: item.codigo,
      Precio: item.precio,
      StockActual: item.stockActual,
      StockMinimo: item.stockMinimo,
      Estado: this.estadoProducto(item.stockActual, item.stockMinimo)
    }));
    this.descargarCsv('reporte-stock.csv', rows);
  }

  exportarPdf(): void {
    this.imprimirReporte('Reporte de stock', this.filtrados.map(item => [
      item.marca,
      item.modelo,
      item.codigo,
      item.stockActual,
      item.stockMinimo,
      this.estadoProducto(item.stockActual, item.stockMinimo)
    ]));
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

  private imprimirReporte(titulo: string, rows: any[][]): void {
    const htmlRows = rows.map(row => `<tr>${row.map(col => `<td>${col ?? ''}</td>`).join('')}</tr>`).join('');
    const win = window.open('', '_blank');
    win?.document.write(`
      <html><head><title>${titulo}</title><style>
        body{font-family:Arial,sans-serif;padding:24px;color:#1f2937}
        table{width:100%;border-collapse:collapse} th,td{border:1px solid #cbd5e1;padding:8px;text-align:left}
        th{background:#7d82ef;color:white}
      </style></head><body>
      <h1>${titulo}</h1>
      <p>Fecha: ${this.fecha}</p>
      <table><thead><tr><th>Marca</th><th>Modelo</th><th>Codigo</th><th>Stock</th><th>Minimo</th><th>Estado</th></tr></thead><tbody>${htmlRows}</tbody></table>
      </body></html>
    `);
    win?.document.close();
    win?.print();
  }
}
