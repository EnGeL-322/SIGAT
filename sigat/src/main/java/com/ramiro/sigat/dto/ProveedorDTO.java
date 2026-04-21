package com.ramiro.sigat.dto;
import lombok.*;
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProveedorDTO {
    private Long id;
    private String nombre;
    private String ruc;
    private String email;
    private String telefono;
    private String direccion;
    private String contacto;
    private Boolean activo;
}
