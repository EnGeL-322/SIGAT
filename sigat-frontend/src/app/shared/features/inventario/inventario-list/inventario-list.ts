import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-inventario-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './inventario-list.html',
  styleUrl: './inventario-list.css'
})
export class InventarioListComponent implements OnInit {
  productos: any[] = [];
  filtrados: any[] = [];
  imeis: any[] = [];
  vendidos: any[] = [];
  selected: any = null;
  detailModal = false;
  soldModal = false;
  loadingVendidos = false;
  itemsPorPagina = 10;
  paginaActual = 1;

  searchMarca = '';
  searchModelo = '';

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerProductos().subscribe((res: any) => {
      this.productos = res?.datos || [];
      this.filtrar();
      this.cdr.detectChanges();
    });
  }

  filtrar(): void {
    const marca = this.searchMarca.toLowerCase().trim();
    const modelo = this.searchModelo.toLowerCase().trim();

    this.filtrados = this.productos.filter(item =>
      item.marca.toLowerCase().includes(marca) &&
      item.modelo.toLowerCase().includes(modelo)
    );
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

  verDetalle(item: any): void {
    this.selected = item;
    this.api.obtenerIMEIPorProducto(item.id).subscribe((res: any) => {
      this.imeis = res?.datos || [];
      this.detailModal = true;
      this.cdr.detectChanges();
    });
  }

  verVendidos(): void {
    this.loadingVendidos = true;
    this.soldModal = true;
    this.api.obtenerIMEIVendidos().subscribe({
      next: (res: any) => {
        this.vendidos = res?.datos || [];
        this.loadingVendidos = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.vendidos = [];
        this.loadingVendidos = false;
        this.cdr.detectChanges();
      }
    });
  }

  contarPorEstado(estado: string): number {
    return this.imeis.filter(imei => imei.estado === estado).length;
  }

  estadoStock(stock: number): string {
    if (stock <= 0) return 'AGOTADO';
    if (stock <= 5) return 'STOCK BAJO';
    return 'DISPONIBLE';
  }

  estadoClass(stock: number): string {
    if (stock <= 0) return 'danger';
    if (stock <= 5) return 'warning';
    return 'success';
  }

  imeiEstadoClass(estado: string): string {
    if (estado === 'VENDIDO') return 'danger';
    if (estado === 'DEFECTUOSO') return 'warning';
    return 'success';
  }
}
