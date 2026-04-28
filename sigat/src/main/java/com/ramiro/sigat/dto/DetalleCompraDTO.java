package com.ramiro.sigat.dto;
import lombok.*;
import java.util.List;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DetalleCompraDTO {
    private Long id;
    private Long compraId;
    private Long productoId;
    private String productoNombre;
    private Integer cantidad;
    private Double precioUnitario;
    private Double subtotal;
    private List<IMEIDTO> imeis;
}
