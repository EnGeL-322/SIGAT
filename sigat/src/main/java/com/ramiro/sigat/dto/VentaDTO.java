package com.ramiro.sigat.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VentaDTO {
    private Long id;
    private String numeroVenta;
    @NotNull(message = "Debe seleccionar un cliente")
    private Long clienteId;
    private String clienteNombre;
    private Long vendedorId;
    private String vendedorNombre;
    private Double total;
    private String estado;
    private java.time.LocalDateTime fechaVenta;
}
