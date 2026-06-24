import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { IMAGE_CONFIG } from '@angular/common';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { authInterceptor } from './core/auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor])),
    {
      provide: IMAGE_CONFIG,
      useValue: {
        disableImageSizeWarning: true
      }
    }
  ]
};
