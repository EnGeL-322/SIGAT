import { ApplicationRef, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = 'http://localhost:8081/api';

  constructor(private http: HttpClient, private appRef: ApplicationRef) {}

  login(email: string, password: string): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/auth/login`, { email, password }));
  }

  register(usuario: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/auth/register`, usuario));
  }

  obtenerAuthConfig(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/auth/config`));
  }

  loginGoogle(idToken: string): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/auth/google`, { idToken }));
  }

  solicitarCodigoPassword(email: string): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/auth/forgot-password`, { email }));
  }

  restablecerPassword(payload: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/auth/reset-password`, payload));
  }

  obtenerProductos(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/productos`));
  }

  obtenerProducto(id: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/productos/${id}`));
  }

  crearProducto(producto: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/productos`, producto));
  }

  actualizarProducto(id: number, producto: any): Observable<any> {
    return this.refreshAfter(this.http.put(`${this.apiUrl}/productos/${id}`, producto));
  }

  eliminarProducto(id: number): Observable<any> {
    return this.refreshAfter(this.http.delete(`${this.apiUrl}/productos/${id}`));
  }

  obtenerProductosBajoStock(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/productos/bajo-stock`));
  }

  obtenerProveedores(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/proveedores`));
  }

  obtenerProveedor(id: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/proveedores/${id}`));
  }

  crearProveedor(proveedor: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/proveedores`, proveedor));
  }

  actualizarProveedor(id: number, proveedor: any): Observable<any> {
    return this.refreshAfter(this.http.put(`${this.apiUrl}/proveedores/${id}`, proveedor));
  }

  eliminarProveedor(id: number): Observable<any> {
    return this.refreshAfter(this.http.delete(`${this.apiUrl}/proveedores/${id}`));
  }

  obtenerClientes(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/clientes`));
  }

  obtenerCliente(id: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/clientes/${id}`));
  }

  crearCliente(cliente: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/clientes`, cliente));
  }

  actualizarCliente(id: number, cliente: any): Observable<any> {
    return this.refreshAfter(this.http.put(`${this.apiUrl}/clientes/${id}`, cliente));
  }

  eliminarCliente(id: number): Observable<any> {
    return this.refreshAfter(this.http.delete(`${this.apiUrl}/clientes/${id}`));
  }

  obtenerCompras(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/compras`));
  }

  obtenerCompra(id: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/compras/${id}`));
  }

  crearCompra(payload: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/compras`, payload));
  }

  obtenerDetallesCompra(compraId: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/compras/${compraId}/detalles`));
  }

  eliminarCompra(id: number): Observable<any> {
    return this.refreshAfter(this.http.delete(`${this.apiUrl}/compras/${id}`));
  }

  obtenerVentas(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/ventas`));
  }

  obtenerVenta(id: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/ventas/${id}`));
  }

  obtenerDetallesVenta(ventaId: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/ventas/${ventaId}/detalles`));
  }

  crearVenta(payload: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/ventas`, payload));
  }

  eliminarVenta(id: number): Observable<any> {
    return this.refreshAfter(this.http.delete(`${this.apiUrl}/ventas/${id}`));
  }

  obtenerIMEIEnStock(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/imei/en-stock`));
  }

  obtenerIMEIPorProducto(productoId: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/imei/producto/${productoId}`));
  }

  obtenerUsuarios(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/usuarios`));
  }

  obtenerUsuario(id: number): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/usuarios/${id}`));
  }

  crearUsuario(usuario: any): Observable<any> {
    return this.refreshAfter(this.http.post(`${this.apiUrl}/usuarios`, usuario));
  }

  actualizarUsuario(id: number, usuario: any): Observable<any> {
    return this.refreshAfter(this.http.put(`${this.apiUrl}/usuarios/${id}`, usuario));
  }

  eliminarUsuario(id: number): Observable<any> {
    return this.refreshAfter(this.http.delete(`${this.apiUrl}/usuarios/${id}`));
  }

  obtenerRoles(): Observable<any> {
    return this.refreshAfter(this.http.get(`${this.apiUrl}/roles`));
  }

  private refreshAfter<T>(request$: Observable<T>): Observable<T> {
    return new Observable<T>((subscriber) => {
      const subscription = request$.subscribe({
        next: (value) => {
          subscriber.next(value);
          this.refreshView();
        },
        error: (error) => {
          this.refreshView();
          subscriber.error(error);
        },
        complete: () => subscriber.complete()
      });

      return () => subscription.unsubscribe();
    });
  }

  private refreshView(): void {
    setTimeout(() => this.appRef.tick(), 0);
  }
}
