package com.ramiro.sigat.dto;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClienteDTO {
    private Long id;
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;
    @NotBlank(message = "El apellido es obligatorio")
    private String apellido;
    @NotBlank(message = "La cedula es obligatoria")
    private String cedula;
    @Email(message = "El email no es valido")
    private String email;
    private String telefono;
    private String direccion;
    private Boolean activo;
}