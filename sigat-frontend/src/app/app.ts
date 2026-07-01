import { Component, OnDestroy, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { AuthService } from './core/auth.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit, OnDestroy {
  constructor(private auth: AuthService) {}

  ngOnInit(): void {
    window.addEventListener('pageshow', this.onPageShow);
  }

  ngOnDestroy(): void {
    window.removeEventListener('pageshow', this.onPageShow);
  }

  /**
   * Se dispara cada vez que la pagina se muestra, incluida la restauracion
   * desde el bfcache del navegador (boton "atras" / "adelante").
   *
   * event.persisted === true  ->  la pagina vino del bfcache y NO se
   * re-ejecutaron los guards de Angular. Si en ese momento ya no hay
   * sesion activa, forzamos una salida limpia a /login.
   */
  private onPageShow = (event: PageTransitionEvent): void => {
    if (event.persisted && !this.auth.isAuthenticated()) {
      window.location.replace('/login');
    }
  };
}
