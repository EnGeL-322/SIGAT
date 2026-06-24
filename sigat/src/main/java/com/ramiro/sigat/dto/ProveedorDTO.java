package com.ramiro.sigat.dto;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProveedorDTO {
    private Long id;
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;
    @NotBlank(message = "El RUC es obligatorio")
    private String ruc;
    @Email(message = "El email no es valido")
    private String email;
    private String telefono;
    private String direccion;
    private String contacto;
    private Boolean activo;
}
