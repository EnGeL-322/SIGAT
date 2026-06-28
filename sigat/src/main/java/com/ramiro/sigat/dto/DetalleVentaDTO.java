package com.ramiro.sigat.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DetalleVentaDTO {
    private Long id;
    private Long ventaId;
    @NotNull(message = "Debe seleccionar un producto")
    private Long productoId;
    private String productoNombre;
    @Positive(message = "La cantidad debe ser mayor a cero")
    private Integer cantidad = 1;
    private Long imeiId;
    private String imeiNumero;
    @NotNull(message = "El precio unitario es obligatorio")
    @Positive(message = "El precio unitario debe ser mayor a cero")
    private Double precioUnitario;
    private Double subtotal;
}
