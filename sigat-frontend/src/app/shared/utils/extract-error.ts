/** Extrae un mensaje de error legible de una respuesta HTTP fallida. */
export function extractError(err: any, fallback: string): string {
  return err?.error?.mensaje || err?.error?.message || err?.message || fallback;
}
