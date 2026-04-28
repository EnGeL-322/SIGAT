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
  selected: any = null;
  detailModal = false;

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
  }

  verDetalle(item: any): void {
    this.selected = item;
    this.api.obtenerIMEIPorProducto(item.id).subscribe((res: any) => {
      this.imeis = res?.datos || [];
      this.detailModal = true;
      this.cdr.detectChanges();
    });
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
}
