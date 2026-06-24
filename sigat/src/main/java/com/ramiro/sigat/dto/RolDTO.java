package com.ramiro.sigat.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RolDTO {
    private Long id;
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;
    private String descripcion;
}