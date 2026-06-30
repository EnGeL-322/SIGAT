import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../../core/api.service';
import { extractError } from '../../../utils/extract-error';

@Component({
  selector: 'app-productos-list',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  templateUrl: './productos-list.html',
  styleUrl: './productos-list.css'
})
export class ProductosListComponent implements OnInit {
  productos: any[] = [];
  productosFiltrados: any[] = [];
  search = '';
  showModal = false;
  detailModal = false;
  selected: any = null;
  editId: number | null = null;
  error = '';
  itemsPorPagina = 10;
  paginaActual = 1;
  form: FormGroup;

  constructor(private api: ApiService, private fb: FormBuilder, private cdr: ChangeDetectorRef) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      codigo: ['', Validators.required],
      descripcion: [''],
      marca: ['', Validators.required],
      modelo: ['', Validators.required],
      memoria: [''],
      ram: [''],
      color: [''],
      precio: [0, Validators.required],
      stockMinimo: [10, Validators.required]
    });
  }

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
    const q = this.search.toLowerCase().trim();
    this.productosFiltrados = this.productos.filter(p =>
      `${p.nombre} ${p.codigo} ${p.marca} ${p.modelo}`.toLowerCase().includes(q)
    );
    this.paginaActual = 1;
  }

  get productosPaginados(): any[] {
    const inicio = (this.paginaActual - 1) * this.itemsPorPagina;
    return this.productosFiltrados.slice(inicio, inicio + this.itemsPorPagina);
  }

  get totalPaginas(): number {
    return Math.max(1, Math.ceil(this.productosFiltrados.length / this.itemsPorPagina));
  }

  get paginas(): number[] {
    return Array.from({ length: this.totalPaginas }, (_, index) => index + 1);
  }

  get inicioPagina(): number {
    if (!this.productosFiltrados.length) return 0;
    return (this.paginaActual - 1) * this.itemsPorPagina + 1;
  }

  get finPagina(): number {
    return Math.min(this.paginaActual * this.itemsPorPagina, this.productosFiltrados.length);
  }

  cambiarPagina(pagina: number): void {
    if (pagina < 1 || pagina > this.totalPaginas) return;
    this.paginaActual = pagina;
  }

  openCreate(): void {
    this.error = '';
    this.editId = null;
    this.selected = null;
    this.form.reset({
      nombre: '',
      codigo: '',
      descripcion: '',
      marca: '',
      modelo: '',
      memoria: '',
      ram: '',
      color: '',
      precio: 0,
      stockMinimo: 10
    });
    this.showModal = true;
  }

  openEdit(item: any): void {
    this.error = '';
    this.editId = item.id;
    this.selected = item;
    this.form.patchValue({
      nombre: item.nombre,
      codigo: item.codigo,
      descripcion: item.descripcion,
      marca: item.marca,
      modelo: item.modelo,
      memoria: item.memoria,
      ram: item.ram,
      color: item.color,
      precio: item.precio,
      stockMinimo: item.stockMinimo
    });
    this.showModal = true;
  }

  openDetail(item: any): void {
    this.selected = item;
    this.detailModal = true;
  }

  save(): void {
    if (this.form.invalid) return;

    this.error = '';
    const payload = this.form.getRawValue();

    if (this.editId) {
      this.api.actualizarProducto(this.editId, payload).subscribe({
        next: () => {
          this.showModal = false;
          this.load();
        },
        error: (err) => {
          this.error = extractError(err, 'No se pudo actualizar el producto');
          this.cdr.detectChanges();
        }
      });
    } else {
      this.api.crearProducto(payload).subscribe({
        next: () => {
          this.showModal = false;
          this.load();
        },
        error: (err) => {
          this.error = extractError(err, 'No se pudo crear el producto');
          this.cdr.detectChanges();
        }
      });
    }
  }

  remove(id: number): void {
    if (!confirm('Eliminar este producto lo ocultara de las listas activas. Deseas continuar?')) return;

    this.error = '';
    this.api.eliminarProducto(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.error = extractError(err, 'No se pudo eliminar el producto');
        this.cdr.detectChanges();
      }
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
