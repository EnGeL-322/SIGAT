package com.ramiro.sigat.models;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "imei")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IMEI {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String numero;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "producto_id", nullable = false)
    private Producto producto;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "compra_id")
    private Compra compra;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "detalle_compra_id")
    private DetalleCompra detalleCompra;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "venta_id")
    private Venta venta;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "detalle_venta_id")
    private DetalleVenta detalleVenta;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private EstadoIMEI estado; // EN_STOCK, VENDIDO, DEFECTUOSO

    @Column(name = "cliente_id")
    private Long clienteId;

    @Column(name = "fecha_ingreso")
    private LocalDateTime fechaIngreso;

    @Column(name = "fecha_venta")
    private LocalDateTime fechaVenta;

    @Column(name = "fecha_actualizacion")
    private LocalDateTime fechaActualizacion;

    @PrePersist
    protected void onCreate() {
        fechaIngreso = LocalDateTime.now();
        fechaActualizacion = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        fechaActualizacion = LocalDateTime.now();
    }

    public enum EstadoIMEI {
        EN_STOCK, VENDIDO, DEFECTUOSO
    }
}
