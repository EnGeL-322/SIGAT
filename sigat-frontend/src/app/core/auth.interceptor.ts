import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { AuthService } from './auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);

  const token = authService.getToken();
  const authReq = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        // Token invalido o expirado: limpiamos la sesion y forzamos una
        // recarga completa hacia /login. Usar window.location.replace (en
        // lugar de router.navigate) destruye la app en memoria y no deja
        // la ruta protegida en el historial del navegador.
        authService.logout();
        window.location.replace('/login');
      }
      return throwError(() => error);
    })
  );
};
