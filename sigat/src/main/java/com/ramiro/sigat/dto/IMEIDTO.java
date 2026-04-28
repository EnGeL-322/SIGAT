package com.ramiro.sigat.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IMEIDTO {
    private Long id;
    private String numero;
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
