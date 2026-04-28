import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-topbar',
  standalone: true,
  templateUrl: './topbar.html',
  styleUrl: './topbar.css'
})
export class TopbarComponent {
  @Input() menuOpen = true;
  @Output() menuToggle = new EventEmitter<void>();
}
