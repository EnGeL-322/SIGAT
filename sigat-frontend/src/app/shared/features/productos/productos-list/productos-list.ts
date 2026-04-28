import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../../core/api.service';

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
  form: FormGroup;

  constructor(private api: ApiService, private fb: FormBuilder, private cdr: ChangeDetectorRef) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      codigo: ['', Validators.required],
      descripcion: [''],
      marca: ['', Validators.required],
      modelo: ['', Validators.required],
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
  }

  openCreate(): void {
    this.editId = null;
    this.selected = null;
    this.form.reset({
      nombre: '',
      codigo: '',
      descripcion: '',
      marca: '',
      modelo: '',
      precio: 0,
      stockMinimo: 10
    });
    this.showModal = true;
  }

  openEdit(item: any): void {
    this.editId = item.id;
    this.selected = item;
    this.form.patchValue({
      nombre: item.nombre,
      codigo: item.codigo,
      descripcion: item.descripcion,
      marca: item.marca,
      modelo: item.modelo,
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

    const payload = this.form.getRawValue();

    if (this.editId) {
      this.api.actualizarProducto(this.editId, payload).subscribe(() => {
        this.showModal = false;
        this.load();
      });
    } else {
      this.api.crearProducto(payload).subscribe(() => {
        this.showModal = false;
        this.load();
      });
    }
  }

  remove(id: number): void {
    this.api.eliminarProducto(id).subscribe(() => this.load());
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
