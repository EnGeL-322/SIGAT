import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../../core/auth.service';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './register.html',
  styleUrl: './register.css'
})
export class RegisterComponent {
  loading = false;
  error = '';
  success = '';
  registerForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.registerForm = this.fb.group(
      {
        nombre: ['', Validators.required],
        apellido: ['', Validators.required],
        email: ['', [Validators.required, Validators.email]],
        password: ['', [Validators.required, Validators.minLength(6)]],
        confirmPassword: ['', [Validators.required]]
      },
      { validators: this.passwordsMatch }
    );
  }

  passwordsMatch(group: AbstractControl) {
    const password = group.get('password')?.value;
    const confirmPassword = group.get('confirmPassword')?.value;
    return password === confirmPassword ? null : { passwordMismatch: true };
  }

  onRegister(): void {
    if (this.registerForm.invalid || this.loading) return;

    this.loading = true;
    this.error = '';
    this.success = '';

    const form = this.registerForm.getRawValue();

    const payload = {
      nombre: form.nombre,
      apellido: form.apellido,
      email: form.email,
      password: form.password,
      rolId: 1
    };

    this.authService.register(payload).subscribe({
      next: (response: any) => {
        this.loading = false;
        if (response?.exito) {
          this.success = 'Registro exitoso';
          setTimeout(() => this.router.navigate(['/login']), 1200);
        } else {
          this.error = response?.mensaje || 'No se pudo registrar';
        }
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.mensaje || 'Error al registrar';
      }
    });
  }
}