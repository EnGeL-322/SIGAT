import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/auth.service';

type MenuSearchItem = {
  label: string;
  group: string;
  route: string;
  keywords: string[];
  adminOnly?: boolean;
};

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './topbar.html',
  styleUrl: './topbar.css'
})
export class TopbarComponent {
  @Input() menuOpen = true;
  @Output() menuToggle = new EventEmitter<void>();

  searchTerm = '';
  searchFocused = false;

  private readonly menuItems: MenuSearchItem[] = [
    { label: 'Compras', group: 'Operaciones', route: '/compras', keywords: ['compra', 'compras', 'operaciones', 'ingreso', 'proveedor'] },
    { label: 'Ventas', group: 'Operaciones', route: '/ventas', keywords: ['venta', 'ventas', 'operaciones', 'salida', 'cliente'] },
    { label: 'Producto', group: 'Maestros', route: '/productos', keywords: ['producto', 'productos', 'celular', 'equipo', 'maestros'] },
    { label: 'Proveedores', group: 'Maestros', route: '/proveedores', keywords: ['proveedor', 'proveedores', 'ruc', 'maestros'] },
    { label: 'Clientes', group: 'Maestros', route: '/clientes', keywords: ['cliente', 'clientes', 'dni', 'maestros'] },
    { label: 'Stock general', group: 'Inventario', route: '/inventario', keywords: ['stock', 'inventario', 'imei', 'equipos', 'general'] },
    { label: 'Reporte ventas', group: 'Reportes', route: '/reportes/ventas', keywords: ['reporte', 'reportes', 'venta', 'ventas', 'pdf', 'excel'] },
    { label: 'Bajo stock', group: 'Reportes', route: '/reportes/bajo-stock', keywords: ['bajo stock', 'stock bajo', 'agotado', 'minimo', 'reportes'] },
    { label: 'Usuarios', group: 'Seguridad', route: '/usuarios', keywords: ['usuario', 'usuarios', 'seguridad', 'roles', 'admin'], adminOnly: true }
  ];

  constructor(private router: Router, private authService: AuthService) {}

  get filteredMenuItems(): MenuSearchItem[] {
    const term = this.normalize(this.searchTerm);
    if (!term) return [];

    return this.visibleMenuItems
      .map((item) => ({ item, score: this.scoreItem(item, term) }))
      .filter((result) => result.score > 0)
      .sort((a, b) => a.score - b.score || a.item.label.localeCompare(b.item.label))
      .map((result) => result.item)
      .slice(0, 6);
  }

  searchMenu(): void {
    const firstResult = this.filteredMenuItems[0];
    if (firstResult) {
      this.goTo(firstResult);
    }
  }

  goTo(item: MenuSearchItem): void {
    this.searchTerm = item.label;
    this.searchFocused = false;
    this.router.navigateByUrl(item.route);
  }

  closeSearchLater(): void {
    setTimeout(() => {
      this.searchFocused = false;
    }, 140);
  }

  private get visibleMenuItems(): MenuSearchItem[] {
    return this.menuItems.filter((item) => !item.adminOnly || this.authService.isAdmin());
  }

  private scoreItem(item: MenuSearchItem, term: string): number {
    const phrases = [item.label, ...item.keywords].map((value) => this.normalize(value));
    const words = phrases.flatMap((phrase) => phrase.split(/\s+/));

    if (phrases.some((phrase) => phrase === term)) return 1;
    if (phrases.some((phrase) => phrase.startsWith(term))) return 2;
    if (words.some((word) => word.startsWith(term))) return 3;
    if (term.length >= 3 && phrases.some((phrase) => phrase.includes(term))) return 4;

    return 0;
  }

  private normalize(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .trim();
  }
}
