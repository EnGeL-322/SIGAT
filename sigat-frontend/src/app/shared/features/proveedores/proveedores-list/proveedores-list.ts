import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-proveedores-list',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  templateUrl: './proveedores-list.html',
  styleUrl: './proveedores-list.css'
})
export class ProveedoresListComponent implements OnInit {
  proveedores: any[] = [];
  filtrados: any[] = [];
  search = '';
  showModal = false;
  detailModal = false;
  selected: any = null;
  editId: number | null = null;
  form: FormGroup;

  constructor(private api: ApiService, private fb: FormBuilder, private cdr: ChangeDetectorRef) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      ruc: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      telefono: ['', Validators.required],
      direccion: [''],
      contacto: ['']
    });
  }

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerProveedores().subscribe((res: any) => {
      this.proveedores = res?.datos || [];
      this.filtrar();
      this.cdr.detectChanges();
    });
  }

  filtrar(): void {
    const q = this.search.toLowerCase().trim();
    this.filtrados = this.proveedores.filter(p =>
      `${p.nombre} ${p.ruc} ${p.email} ${p.telefono}`.toLowerCase().includes(q)
    );
  }

  openCreate(): void {
    this.editId = null;
    this.form.reset({
      nombre: '',
      ruc: '',
      email: '',
      telefono: '',
      direccion: '',
      contacto: ''
    });
    this.showModal = true;
  }

  openEdit(item: any): void {
    this.editId = item.id;
    this.selected = item;
    this.form.patchValue(item);
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
      this.api.actualizarProveedor(this.editId, payload).subscribe(() => {
        this.showModal = false;
        this.load();
      });
    } else {
      this.api.crearProveedor(payload).subscribe(() => {
        this.showModal = false;
        this.load();
      });
    }
  }

  remove(id: number): void {
    this.api.eliminarProveedor(id).subscribe(() => this.load());
  }
}
