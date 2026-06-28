package com.ramiro.sigat.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VentaRequestDTO {
    @Valid
    @NotNull(message = "Debe indicar los datos de la venta")
    private VentaDTO venta;

    @Valid
    @NotEmpty(message = "La venta debe tener al menos un detalle")
    private List<DetalleVentaDTO> detalles;
}
