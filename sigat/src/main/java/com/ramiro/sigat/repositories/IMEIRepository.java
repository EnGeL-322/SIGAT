package com.ramiro.sigat.repositories;

import com.ramiro.sigat.models.IMEI;
import org.springframework.data.jpa.repository.JpaRepository;
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
}
