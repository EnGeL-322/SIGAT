import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class LoginComponent {
  error = '';
  loading = false;
  loginForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required]]
    });
  }

  onLogin(): void {
    if (this.loginForm.invalid || this.loading) return;

    this.error = '';
    this.loading = true;

    const { email, password } = this.loginForm.getRawValue();

    this.authService.login(email ?? '', password ?? '').subscribe({
      next: (response: any) => {
        this.loading = false;
        if (response?.exito) {
          this.router.navigate(['/dashboard']);
        } else {
          this.error = response?.mensaje || 'Credenciales inválidas';
        }
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.mensaje || 'Error al iniciar sesión';
      }
    });
  }
}