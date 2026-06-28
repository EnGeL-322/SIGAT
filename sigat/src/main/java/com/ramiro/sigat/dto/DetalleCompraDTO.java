package com.ramiro.sigat.dto;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
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
    @NotNull(message = "Debe seleccionar un producto")
    private Long productoId;
    private String productoNombre;
    @NotNull(message = "La cantidad es obligatoria")
    @Positive(message = "La cantidad debe ser mayor a cero")
    private Integer cantidad;
    @NotNull(message = "El precio unitario es obligatorio")
    @Positive(message = "El precio unitario debe ser mayor a cero")
    private Double precioUnitario;
    private Double subtotal;
    private List<IMEIDTO> imeis;
}
