package com.ramiro.sigat.repositories;

import com.ramiro.sigat.models.Venta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;
@Repository
public interface VentaRepository extends JpaRepository<Venta, Long> {
    Optional<Venta> findByNumeroVenta(String numeroVenta);
    List<Venta> findByClienteId(Long clienteId);
    List<Venta> findByEstado(Venta.EstadoVenta estado);
}
