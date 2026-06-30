package com.ramiro.sigat.models;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "ventas")
@Getter
@Setter
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Venta {

    @EqualsAndHashCode.Include
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String numeroVenta;

    @Column(name = "tipo_comprobante")
    private String tipoComprobante;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "cliente_id", nullable = false)
    private Cliente cliente;

    @Column(nullable = false)
    private Double total;

    @Column(name = "vendedor_id")
    private Long vendedorId;

    @Column(name = "vendedor_nombre")
    private String vendedorNombre;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private EstadoVenta estado; // COMPLETADA, CANCELADA, PENDIENTE

    @OneToMany(mappedBy = "venta", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DetalleVenta> detalles;

    @Column(name = "fecha_venta")
    private LocalDateTime fechaVenta;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    @PrePersist
    protected void onCreate() {
        fechaVenta = LocalDateTime.now();
        fechaCreacion = LocalDateTime.now();
    }

    public enum EstadoVenta {
        COMPLETADA, CANCELADA, PENDIENTE
    }
}
