package com.ramiro.sigat.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DetalleVentaDTO {
    private Long id;
    private Long ventaId;
    private Long productoId;
    private String productoNombre;
    private Integer cantidad;
    private Long imeiId;
    private String imeiNumero;
    private Double precioUnitario;
    private Double subtotal;
}
