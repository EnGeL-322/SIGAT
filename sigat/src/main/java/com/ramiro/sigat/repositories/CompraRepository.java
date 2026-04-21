package com.ramiro.sigat.repositories;

import com.ramiro.sigat.models.Compra;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface CompraRepository extends JpaRepository<Compra, Long> {
    Optional<Compra> findByNumeroCompra(String numeroCompra);
    List<Compra> findByProveedorId(Long proveedorId);
    List<Compra> findByEstado(Compra.EstadoCompra estado);
}