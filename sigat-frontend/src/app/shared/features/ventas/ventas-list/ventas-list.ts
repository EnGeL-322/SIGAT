import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-ventas-list',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './ventas-list.html',
  styleUrl: './ventas-list.css'
})
export class VentasListComponent implements OnInit {
  ventas: any[] = [];
  detalles: any[] = [];
  detailModal = false;
  selected: any = null;

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.api.obtenerVentas().subscribe((res: any) => {
      this.ventas = res?.datos || [];
      this.cdr.detectChanges();
    });
  }

  verDetalle(item: any): void {
    this.selected = item;
    this.api.obtenerDetallesVenta(item.id).subscribe((res: any) => {
      this.detalles = res?.datos || [];
      this.detailModal = true;
      this.cdr.detectChanges();
    });
  }
}
