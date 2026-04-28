import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SidebarComponent } from '../../shared/components/sidebar/sidebar';
import { TopbarComponent } from '../../shared/components/topbar/topbar';

@Component({
  selector: 'app-dashboard-layout',
  standalone: true,
  imports: [RouterOutlet, SidebarComponent, TopbarComponent],
  templateUrl: './dashboard-layout.html',
  styleUrl: './dashboard-layout.css'
})
export class DashboardLayoutComponent {}