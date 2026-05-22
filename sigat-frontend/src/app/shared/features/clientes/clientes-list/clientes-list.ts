import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-clientes-list',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  templateUrl: './clientes-list.html',
  styleUrl: './clientes-list.css'
})
export class ClientesListComponent implements OnInit {
  clientes: any[] = [];
  filtrados: any[] = [];
  search = '';
  showModal = false;
  detailModal = false;
  selected: any = null;
  editId: number | null = null;
  error = '';
  form: FormGroup;

  constructor(private api: ApiService, private fb: FormBuilder, private cdr: ChangeDetectorRef) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      apellido: ['', Validators.required],
      cedula: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      telefono: ['', Validators.required],
      direccion: ['']
    });
  }

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerClientes().subscribe((res: any) => {
      this.clientes = res?.datos || [];
      this.filtrar();
      this.cdr.detectChanges();
    });
  }

  filtrar(): void {
    const q = this.search.toLowerCase().trim();
    this.filtrados = this.clientes.filter(c =>
      `${c.nombre} ${c.apellido} ${c.cedula} ${c.email}`.toLowerCase().includes(q)
    );
  }

  openCreate(): void {
    this.error = '';
    this.editId = null;
    this.form.reset({
      nombre: '',
      apellido: '',
      cedula: '',
      email: '',
      telefono: '',
      direccion: ''
    });
    this.showModal = true;
  }

  openEdit(item: any): void {
    this.error = '';
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
    this.error = '';
    const payload = this.form.getRawValue();

    if (this.editId) {
      this.api.actualizarCliente(this.editId, payload).subscribe({
        next: () => {
          this.showModal = false;
          this.load();
        },
        error: (err) => {
          this.error = this.extractError(err, 'No se pudo actualizar el cliente');
          this.cdr.detectChanges();
        }
      });
    } else {
      this.api.crearCliente(payload).subscribe({
        next: () => {
          this.showModal = false;
          this.load();
        },
        error: (err) => {
          this.error = this.extractError(err, 'No se pudo crear el cliente');
          this.cdr.detectChanges();
        }
      });
    }
  }

  remove(id: number): void {
    if (!confirm('Eliminar este cliente lo ocultara de las listas activas. Deseas continuar?')) return;

    this.error = '';
    this.api.eliminarCliente(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.error = this.extractError(err, 'No se pudo eliminar el cliente');
        this.cdr.detectChanges();
      }
    });
  }

  private extractError(err: any, fallback: string): string {
    return err?.error?.mensaje || err?.error?.message || err?.message || fallback;
  }
}
