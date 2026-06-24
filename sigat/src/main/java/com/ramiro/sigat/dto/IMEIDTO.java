package com.ramiro.sigat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IMEIDTO {
    private Long id;
    @NotBlank(message = "El numero de IMEI es obligatorio")
    private String numero;
    @NotNull(message = "Debe indicar el producto")
    private Long productoId;
    private String productoNombre;
    private String estado;
    private Long compraId;
    private String numeroCompra;
    private Long proveedorId;
    private String proveedorNombre;
    private java.time.LocalDateTime fechaIngreso;
    private Long ventaId;
    private String numeroVenta;
    private Long clienteId;
    private String clienteNombre;
    private java.time.LocalDateTime fechaVenta;
}
