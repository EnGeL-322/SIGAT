package com.ramiro.sigat.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UsuarioDTO {
    private Long id;
    @NotBlank(message = "El email es obligatorio")
    @Email(message = "El email no es valido")
    private String email;
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;
    @NotBlank(message = "El apellido es obligatorio")
    private String apellido;
    private String password;
    private Long rolId;
    private String rolNombre;
    private Boolean activo;
}