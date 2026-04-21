package com.ramiro.sigat.repositories;

import com.ramiro.sigat.models.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface ProductoRepository extends JpaRepository<Producto, Long> {
    Optional<Producto> findByCodigo(String codigo);
    List<Producto> findByActivo(Boolean activo);
    List<Producto> findByStockActualLessThan(Integer stockMinimo);
}