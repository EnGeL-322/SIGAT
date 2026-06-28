package com.ramiro.sigat.dto;
import jakarta.validation.constraints.NotNull;
import lombok.*;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompraDTO {
    private Long id;
    private String numeroCompra;
    @NotNull(message = "Debe seleccionar un proveedor")
    private Long proveedorId;
    private String proveedorNombre;
    private Double total;
    private String estado;
    private java.time.LocalDateTime fechaCompra;
}
