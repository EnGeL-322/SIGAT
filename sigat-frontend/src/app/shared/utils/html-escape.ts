/**
 * Escapa texto antes de interpolarlo en HTML construido a mano (document.write,
 * exportes a Excel/PDF). Sin esto, un nombre de cliente/proveedor/producto con
 * "<script>" se ejecuta en la ventana de impresion (XSS almacenado).
 */
export function escapeHtml(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}
