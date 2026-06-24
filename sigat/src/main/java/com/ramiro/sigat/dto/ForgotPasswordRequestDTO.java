package com.ramiro.sigat.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ForgotPasswordRequestDTO {
    @NotBlank(message = "El email es obligatorio")
    @Email(message = "El email no es valido")
    private String email;
}
