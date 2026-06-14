package com.ramiro.sigat.dto;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductoDTO {
    private Long id;
    private String nombre;
    private String codigo;
    private String descripcion;
    private String marca;
    private String modelo;
    private String memoria;
    private String ram;
    private String color;
    private Double precio;
    private Integer stockActual;
    private Integer stockMinimo;
    private Boolean activo;
}