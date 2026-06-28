package com.ramiro.sigat.repositories;

import com.ramiro.sigat.models.IMEI;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;
@Repository
public interface IMEIRepository extends JpaRepository<IMEI, Long> {
    Optional<IMEI> findByNumero(String numero);
    List<IMEI> findByProductoId(Long productoId);
    List<IMEI> findByProductoIdAndEstado(Long productoId, IMEI.EstadoIMEI estado);
    List<IMEI> findByCompraId(Long compraId);
    List<IMEI> findByDetalleCompraId(Long detalleCompraId);
    List<IMEI> findByVentaId(Long ventaId);
    List<IMEI> findByDetalleVentaId(Long detalleVentaId);
    List<IMEI> findByEstado(IMEI.EstadoIMEI estado);
    List<IMEI> findByClienteId(Long clienteId);

    /**
     * Bloquea la fila (SELECT ... FOR UPDATE) para evitar que dos ventas
     * concurrentes tomen el mismo IMEI antes de que la primera confirme.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM IMEI i WHERE i.id = :id")
    Optional<IMEI> findByIdForUpdate(@Param("id") Long id);

    /**
     * Igual que findByProductoIdAndEstado pero bloqueando las filas devueltas,
     * para que dos ventas simultaneas no reserven el mismo lote de IMEIs.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM IMEI i WHERE i.producto.id = :productoId AND i.estado = :estado ORDER BY i.id")
    List<IMEI> findByProductoIdAndEstadoForUpdate(
            @Param("productoId") Long productoId,
            @Param("estado") IMEI.EstadoIMEI estado
    );
}
