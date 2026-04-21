package com.ramiro.sigat.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IMEIDTO {
    private Long id;
    private String numero;
    private Long productoId;
    private String estado;
    private Long clienteId;
}