import { Injectable } from '@angular/core';
import { BehaviorSubject, tap } from 'rxjs';
import { ApiService } from './api.service';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly tokenKey = 'sigat_token';
  private readonly userKey = 'sigat_user';

  private userSubject = new BehaviorSubject<any>(this.getStoredUser());
  user$ = this.userSubject.asObservable();

  constructor(private api: ApiService) {}

  login(email: string, password: string) {
    return this.api.login(email, password).pipe(
      tap((response: any) => {
        if (response?.exito) {
          localStorage.setItem(this.tokenKey, response.datos.token);
          localStorage.setItem(this.userKey, JSON.stringify(response.datos));
          this.userSubject.next(response.datos);
        }
      })
    );
  }

  register(payload: any) {
    return this.api.register(payload);
  }

  logout(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);
    this.userSubject.next(null);
  }

  isAuthenticated(): boolean {
    return !!localStorage.getItem(this.tokenKey);
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  getUser(): any {
    return this.userSubject.value;
  }

  private getStoredUser(): any {
    const raw = localStorage.getItem(this.userKey);
    return raw ? JSON.parse(raw) : null;
  }
}