package com.ramiro.sigat.dto;
import lombok.*;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompraDTO {
    private Long id;
    private String numeroCompra;
    private Long proveedorId;
    private String proveedorNombre;
    private Double total;
    private String estado;
    private java.time.LocalDateTime fechaCompra;
}
