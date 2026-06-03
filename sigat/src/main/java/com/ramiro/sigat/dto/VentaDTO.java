package com.ramiro.sigat.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VentaDTO {
    private Long id;
    private String numeroVenta;
    private Long clienteId;
    private String clienteNombre;
    private Long vendedorId;
    private String vendedorNombre;
    private Double total;
    private String estado;
    private java.time.LocalDateTime fechaVenta;
}
