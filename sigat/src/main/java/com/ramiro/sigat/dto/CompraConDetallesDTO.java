package com.ramiro.sigat.dto;

import lombok.*;

import java.util.List;

/**
 * Compra junto con sus detalles en un solo objeto, para que un cliente
 * (reportes movil/web) no tenga que pedir el detalle de cada compra con
 * una peticion HTTP por fila (N+1).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompraConDetallesDTO {
    private CompraDTO compra;
    private List<DetalleCompraDTO> detalles;
}
