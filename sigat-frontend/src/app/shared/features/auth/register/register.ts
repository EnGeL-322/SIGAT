import { Component, NgZone, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../../core/auth.service';

declare const google: any;
declare const FB: any;

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './register.html',
  styleUrl: './register.css'
})
export class RegisterComponent implements OnInit {
  loading = false;
  error = '';
  success = '';
  googleClientId = '';
  facebookAppId = '';
  googleConfigLoaded = false;
  private googleReady = false;
  private facebookReady = false;
  registerForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router,
    private zone: NgZone
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

  ngOnInit(): void {
    this.authService.getAuthConfig().subscribe({
      next: (res: any) => {
        this.googleClientId = res?.datos?.googleClientId || '';
        this.facebookAppId = res?.datos?.facebookAppId || '';
        this.googleConfigLoaded = true;
      },
      error: () => {
        this.googleConfigLoaded = true;
      }
    });
  }

  get googleConfigured(): boolean {
    return !!this.googleClientId;
  }

  get facebookConfigured(): boolean {
    return !!this.facebookAppId;
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
      password: form.password
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

  onGoogleRegister(): void {
    this.error = '';
    this.success = '';

    if (!this.googleClientId) {
      return;
    }

    this.loadGoogleScript()
      .then(() => {
        if (!this.googleReady) {
          google.accounts.id.initialize({
            client_id: this.googleClientId,
            callback: (response: any) => this.zone.run(() => this.handleGoogleCredential(response?.credential))
          });
          this.googleReady = true;
        }

        google.accounts.id.prompt();
      })
      .catch(() => {
        this.error = 'No se pudo cargar Google. Revisa tu conexion.';
      });
  }

  private handleGoogleCredential(credential: string): void {
    if (!credential) {
      this.error = 'Google no devolvio credenciales.';
      return;
    }

    this.loading = true;
    this.authService.loginWithGoogle(credential).subscribe({
      next: (response: any) => {
        this.loading = false;
        if (response?.exito) {
          this.router.navigate(['/dashboard']);
        } else {
          this.error = response?.mensaje || 'No se pudo iniciar sesion con Google';
        }
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.mensaje || 'No se pudo iniciar sesion con Google';
      }
    });
  }

  onFacebookRegister(): void {
    this.error = '';
    this.success = '';

    if (!this.facebookAppId) {
      return;
    }

    this.loadFacebookSdk()
      .then(() => {
        FB.login(
          (response: any) => this.zone.run(() => {
            const token = response?.authResponse?.accessToken;
            if (token) {
              this.handleFacebookToken(token);
            } else {
              this.error = 'No se completo el inicio de sesion con Facebook.';
            }
          }),
          { scope: 'email,public_profile' }
        );
      })
      .catch(() => {
        this.error = 'No se pudo cargar Facebook. Revisa tu conexion.';
      });
  }

  private handleFacebookToken(accessToken: string): void {
    this.loading = true;
    this.authService.loginWithFacebook(accessToken).subscribe({
      next: (response: any) => {
        this.loading = false;
        if (response?.exito) {
          this.router.navigate(['/dashboard']);
        } else {
          this.error = response?.mensaje || 'No se pudo registrar con Facebook';
        }
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.mensaje || 'No se pudo registrar con Facebook';
      }
    });
  }

  private loadFacebookSdk(): Promise<void> {
    if (this.facebookReady && typeof FB !== 'undefined') {
      return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
      const init = () => {
        FB.init({ appId: this.facebookAppId, cookie: true, xfbml: false, version: 'v19.0' });
        this.facebookReady = true;
        resolve();
      };

      if (typeof FB !== 'undefined') {
        init();
        return;
      }

      (window as any).fbAsyncInit = init;

      const script = document.createElement('script');
      script.id = 'facebook-jssdk';
      script.src = 'https://connect.facebook.net/es_LA/sdk.js';
      script.async = true;
      script.defer = true;
      script.crossOrigin = 'anonymous';
      script.onerror = () => reject();
      document.body.appendChild(script);
    });
  }

  private loadGoogleScript(): Promise<void> {
    const existing = document.getElementById('google-identity-services');
    if (existing) return Promise.resolve();

    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.id = 'google-identity-services';
      script.src = 'https://accounts.google.com/gsi/client';
      script.async = true;
      script.defer = true;
      script.onload = () => resolve();
      script.onerror = () => reject();
      document.head.appendChild(script);
    });
  }
}
