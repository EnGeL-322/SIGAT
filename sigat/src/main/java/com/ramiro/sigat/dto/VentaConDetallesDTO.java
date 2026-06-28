package com.ramiro.sigat.dto;

import lombok.*;

import java.util.List;

/**
 * Venta junto con sus detalles en un solo objeto, para que un cliente
 * (reportes movil/web) no tenga que pedir el detalle de cada venta con
 * una peticion HTTP por fila (N+1).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VentaConDetallesDTO {
    private VentaDTO venta;
    private List<DetalleVentaDTO> detalles;
}
