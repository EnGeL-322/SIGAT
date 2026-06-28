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
public class CompraRequestDTO {
    @Valid
    @NotNull(message = "Debe indicar los datos de la compra")
    private CompraDTO compra;

    @Valid
    @NotEmpty(message = "La compra debe tener al menos un detalle")
    private List<DetalleCompraDTO> detalles;
}
