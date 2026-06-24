package com.ramiro.sigat.dto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductoDTO {
    private Long id;
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;
    @NotBlank(message = "El codigo es obligatorio")
    private String codigo;
    private String descripcion;
    private String marca;
    private String modelo;
    private String memoria;
    private String ram;
    private String color;
    @NotNull(message = "El precio es obligatorio")
    @PositiveOrZero(message = "El precio no puede ser negativo")
    private Double precio;
    private Integer stockActual;
    @PositiveOrZero(message = "El stock minimo no puede ser negativo")
    private Integer stockMinimo;
    private Boolean activo;
}