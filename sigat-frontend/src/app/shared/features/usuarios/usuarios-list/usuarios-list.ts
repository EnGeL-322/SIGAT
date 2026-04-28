import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-usuarios-list',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  templateUrl: './usuarios-list.html',
  styleUrl: './usuarios-list.css'
})
export class UsuariosListComponent implements OnInit {
  usuarios: any[] = [];
  filtrados: any[] = [];
  search = '';
  showModal = false;
  editId: number | null = null;
  form: FormGroup;

  constructor(private api: ApiService, private fb: FormBuilder, private cdr: ChangeDetectorRef) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      apellido: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required],
      rolId: [1, Validators.required]
    });
  }

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerUsuarios().subscribe((res: any) => {
      this.usuarios = res?.datos || [];
      this.filtrar();
      this.cdr.detectChanges();
    });
  }

  filtrar(): void {
    const q = this.search.toLowerCase().trim();
    this.filtrados = this.usuarios.filter(u =>
      `${u.nombre} ${u.apellido} ${u.email} ${u.rolNombre}`.toLowerCase().includes(q)
    );
  }

  openCreate(): void {
    this.editId = null;
    this.form.reset({
      nombre: '',
      apellido: '',
      email: '',
      password: '',
      rolId: 1
    });
    this.showModal = true;
  }

  openEdit(user: any): void {
    this.editId = user.id;
    this.form.patchValue({
      nombre: user.nombre,
      apellido: user.apellido,
      email: user.email,
      password: '',
      rolId: user.rolId || 1
    });
    this.showModal = true;
  }

  save(): void {
    if (this.form.invalid) return;

    const payload = this.form.getRawValue();

    if (this.editId) {
      this.api.actualizarUsuario(this.editId, payload).subscribe(() => {
        this.showModal = false;
        this.load();
      });
    } else {
      this.api.crearUsuario(payload).subscribe(() => {
        this.showModal = false;
        this.load();
      });
    }
  }

  remove(id: number): void {
    this.api.eliminarUsuario(id).subscribe(() => this.load());
  }
}
