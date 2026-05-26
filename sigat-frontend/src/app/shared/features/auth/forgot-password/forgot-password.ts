import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../../core/auth.service';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './forgot-password.html',
  styleUrl: './forgot-password.css'
})
export class ForgotPasswordComponent {
  step: 'email' | 'reset' = 'email';
  loading = false;
  error = '';
  success = '';

  emailForm: FormGroup;
  resetForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.emailForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]]
    });

    this.resetForm = this.fb.group(
      {
        code: ['', [Validators.required, Validators.minLength(6), Validators.maxLength(6)]],
        newPassword: ['', [Validators.required, Validators.minLength(6)]],
        confirmPassword: ['', Validators.required]
      },
      { validators: this.passwordsMatch }
    );
  }

  passwordsMatch(group: AbstractControl) {
    return group.get('newPassword')?.value === group.get('confirmPassword')?.value
      ? null
      : { passwordMismatch: true };
  }

  sendCode(): void {
    if (this.emailForm.invalid || this.loading) return;

    this.loading = true;
    this.error = '';
    this.success = '';

    const email = this.emailForm.getRawValue().email;
    this.authService.requestPasswordReset(email).subscribe({
      next: (res: any) => {
        this.loading = false;
        if (res?.exito) {
          this.step = 'reset';
          this.success = 'Te enviamos un codigo unico a tu correo.';
        } else {
          this.error = res?.mensaje || 'No se pudo enviar el codigo';
        }
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.mensaje || 'No se pudo enviar el codigo';
      }
    });
  }

  resetPassword(): void {
    if (this.resetForm.invalid || this.loading) return;

    this.loading = true;
    this.error = '';
    this.success = '';

    const form = this.resetForm.getRawValue();
    const payload = {
      email: this.emailForm.getRawValue().email,
      code: form.code,
      newPassword: form.newPassword
    };

    this.authService.resetPassword(payload).subscribe({
      next: (res: any) => {
        this.loading = false;
        if (res?.exito) {
          this.success = 'Contrasena actualizada. Ya puedes iniciar sesion.';
          setTimeout(() => this.router.navigate(['/login']), 1200);
        } else {
          this.error = res?.mensaje || 'No se pudo actualizar la contrasena';
        }
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.mensaje || 'No se pudo actualizar la contrasena';
      }
    });
  }
}
