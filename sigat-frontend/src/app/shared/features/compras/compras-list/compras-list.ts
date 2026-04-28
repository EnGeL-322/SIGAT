import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../../../core/api.service';

@Component({
  selector: 'app-compras-list',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './compras-list.html',
  styleUrl: './compras-list.css'
})
export class ComprasListComponent implements OnInit {
  compras: any[] = [];

  constructor(private api: ApiService, private cdr: ChangeDetectorRef) {}

  ngOnInit(): void {
    this.api.obtenerCompras().subscribe((res: any) => {
      this.compras = res?.datos || [];
      this.cdr.detectChanges();
    });
  }
}
