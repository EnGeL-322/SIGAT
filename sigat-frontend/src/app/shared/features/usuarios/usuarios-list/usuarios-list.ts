import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../../../core/api.service';
import { extractError } from '../../../utils/extract-error';

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
  roles: any[] = [
    { id: 1, nombre: 'ADMIN' },
    { id: 2, nombre: 'TRABAJADOR' }
  ];
  search = '';
  showModal = false;
  editId: number | null = null;
  error = '';
  form: FormGroup;

  constructor(private api: ApiService, private fb: FormBuilder, private cdr: ChangeDetectorRef) {
    this.form = this.fb.group({
      nombre: ['', Validators.required],
      apellido: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      password: ['', Validators.required],
      rolId: [1, [Validators.required, Validators.min(1)]]
    });
  }

  ngOnInit(): void {
    this.loadRoles();
    this.load();
  }

  loadRoles(): void {
    this.api.obtenerRoles().subscribe({
      next: (res: any) => {
        const roles = res?.datos || [];
        if (roles.length) {
          this.roles = this.prepareRoles(roles);
        }
        this.cdr.markForCheck();
      },
      error: () => this.cdr.markForCheck()
    });
  }

  load(): void {
    this.api.obtenerUsuarios().subscribe((res: any) => {
      this.usuarios = (res?.datos || []).map((usuario: any) => ({
        ...usuario,
        rolNombre: this.displayRole(usuario.rolNombre)
      }));
      this.filtrar();
      this.cdr.markForCheck();
    });
  }

  filtrar(): void {
    const q = this.search.toLowerCase().trim();
    this.filtrados = this.usuarios.filter(u =>
      `${u.nombre} ${u.apellido} ${u.email} ${u.rolNombre}`.toLowerCase().includes(q)
    );
  }

  openCreate(): void {
    this.error = '';
    this.editId = null;
    this.form.get('password')?.setValidators([Validators.required]);
    this.form.get('password')?.updateValueAndValidity();
    this.form.reset({
      nombre: '',
      apellido: '',
      email: '',
      password: '',
      rolId: this.roles[0]?.id || 1
    });
    this.showModal = true;
  }

  openEdit(user: any): void {
    this.error = '';
    this.editId = user.id;
    this.form.get('password')?.clearValidators();
    this.form.get('password')?.updateValueAndValidity();
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

    this.error = '';
    const payload = this.form.getRawValue();
    payload.password = payload.password?.trim();

    if (this.editId && !payload.password) {
      delete payload.password;
    }

    if (this.editId) {
      this.api.actualizarUsuario(this.editId, payload).subscribe({
        next: () => this.closeModalAndReload(),
        error: (err) => {
          this.error = extractError(err, 'No se pudo actualizar el usuario');
          this.cdr.markForCheck();
        }
      });
    } else {
      this.api.crearUsuario(payload).subscribe({
        next: () => this.closeModalAndReload(),
        error: (err) => {
          this.error = extractError(err, 'No se pudo crear el usuario');
          this.cdr.markForCheck();
        }
      });
    }
  }

  remove(id: number): void {
    if (!confirm('Eliminar este usuario lo desactivara del sistema. Deseas continuar?')) return;

    this.error = '';
    this.api.eliminarUsuario(id).subscribe({
      next: () => this.load(),
      error: (err) => {
        this.error = extractError(err, 'No se pudo eliminar el usuario');
        this.cdr.markForCheck();
      }
    });
  }

  displayRole(role: string | null | undefined): string {
    const normalized = this.normalizeRole(role);
    if (normalized.includes('ADMIN')) return 'ADMIN';
    return 'TRABAJADOR';
  }

  private prepareRoles(roles: any[]): any[] {
    const unique = new Map<string, any>();
    roles.forEach((rol) => {
      const nombre = this.displayRole(rol.nombre);
      unique.set(nombre, { ...rol, nombre });
    });

    return Array.from(unique.values()).sort((a, b) => {
      if (a.nombre === 'ADMIN') return -1;
      if (b.nombre === 'ADMIN') return 1;
      return a.nombre.localeCompare(b.nombre);
    });
  }

  private normalizeRole(role: string | null | undefined): string {
    return (role || '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toUpperCase()
      .trim();
  }

  private closeModalAndReload(): void {
    setTimeout(() => {
      this.showModal = false;
      this.load();
      this.cdr.markForCheck();
    }, 0);
  }
}
