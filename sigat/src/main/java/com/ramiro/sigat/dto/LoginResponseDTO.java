package com.ramiro.sigat.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponseDTO {
    private String token;
    private Long usuarioId;
    private String nombre;
    private String email;
    private String rol;
}