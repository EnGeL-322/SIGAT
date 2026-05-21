package com.ramiro.sigat.services;

import com.ramiro.sigat.dto.DetalleVentaDTO;
import com.ramiro.sigat.dto.VentaDTO;
import com.ramiro.sigat.models.Cliente;
import com.ramiro.sigat.models.DetalleVenta;
import com.ramiro.sigat.models.IMEI;
import com.ramiro.sigat.models.Producto;
import com.ramiro.sigat.models.Venta;
import com.ramiro.sigat.repositories.ClienteRepository;
import com.ramiro.sigat.repositories.DetalleVentaRepository;
import com.ramiro.sigat.repositories.IMEIRepository;
import com.ramiro.sigat.repositories.ProductoRepository;
import com.ramiro.sigat.repositories.VentaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class VentaService {
    private final VentaRepository ventaRepository;
    private final DetalleVentaRepository detalleVentaRepository;
    private final ClienteRepository clienteRepository;
    private final ProductoRepository productoRepository;
    private final IMEIRepository imeiRepository;
    private final IMEIService imeiService;

    public VentaService(
            VentaRepository ventaRepository,
            DetalleVentaRepository detalleVentaRepository,
            ClienteRepository clienteRepository,
            ProductoRepository productoRepository,
            IMEIRepository imeiRepository,
            IMEIService imeiService
    ) {
        this.ventaRepository = ventaRepository;
        this.detalleVentaRepository = detalleVentaRepository;
        this.clienteRepository = clienteRepository;
        this.productoRepository = productoRepository;
        this.imeiRepository = imeiRepository;
        this.imeiService = imeiService;
    }

    @Transactional
    public VentaDTO crearVenta(VentaDTO dto, List<DetalleVentaDTO> detalles) {
        if (detalles == null || detalles.isEmpty()) {
            throw new RuntimeException("La venta debe tener al menos un detalle");
        }

        Cliente cliente = clienteRepository.findById(dto.getClienteId())
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));

        Venta venta = new Venta();
        venta.setNumeroVenta(generarNumeroVenta());
        venta.setCliente(cliente);
        venta.setEstado(Venta.EstadoVenta.COMPLETADA);
        venta.setTotal(0.0);
        venta = ventaRepository.save(venta);

        double total = 0.0;

        for (DetalleVentaDTO detalleDto : detalles) {
            validarDetalle(detalleDto);

            Producto producto = productoRepository.findById(detalleDto.getProductoId())
                    .orElseThrow(() -> new RuntimeException("Producto no encontrado"));

            List<IMEI> imeis = obtenerImeisParaVenta(detalleDto, producto);

            for (IMEI imei : imeis) {
                DetalleVenta detalle = new DetalleVenta();
                detalle.setVenta(venta);
                detalle.setProducto(producto);
                detalle.setImei(imei);
                detalle.setPrecioUnitario(detalleDto.getPrecioUnitario());
                detalle.calcularSubtotal();
                detalleVentaRepository.save(detalle);

                total += detalle.getSubtotal();

                imei.setVenta(venta);
                imei.setDetalleVenta(detalle);
                imei.setEstado(IMEI.EstadoIMEI.VENDIDO);
                imei.setClienteId(cliente.getId());
                imei.setFechaVenta(LocalDateTime.now());
                imeiRepository.save(imei);
            }

            producto.setStockActual(producto.getStockActual() - imeis.size());
            productoRepository.save(producto);
        }

        venta.setTotal(total);
        return convertirADTO(ventaRepository.save(venta));
    }

    @Transactional(readOnly = true)
    public VentaDTO obtenerPorId(Long id) {
        Venta venta = ventaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Venta no encontrada"));
        return convertirADTO(venta);
    }

    @Transactional(readOnly = true)
    public List<VentaDTO> listarTodas() {
        return ventaRepository.findAll().stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<VentaDTO> listarPorCliente(Long clienteId) {
        return ventaRepository.findByClienteId(clienteId).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<DetalleVentaDTO> obtenerDetalles(Long ventaId) {
        return detalleVentaRepository.findByVentaId(ventaId).stream()
                .map(this::convertirDetalleADTO)
                .toList();
    }

    @Transactional
    public void eliminar(Long ventaId) {
        Venta venta = ventaRepository.findById(ventaId)
                .orElseThrow(() -> new RuntimeException("Venta no encontrada"));
        List<DetalleVenta> detalles = detalleVentaRepository.findByVentaId(ventaId);

        for (DetalleVenta detalle : detalles) {
            Producto producto = detalle.getProducto();
            producto.setStockActual((producto.getStockActual() == null ? 0 : producto.getStockActual()) + 1);
            productoRepository.save(producto);

            IMEI imei = detalle.getImei();
            imei.setEstado(IMEI.EstadoIMEI.EN_STOCK);
            imei.setVenta(null);
            imei.setDetalleVenta(null);
            imei.setClienteId(null);
            imei.setFechaVenta(null);
            imeiRepository.save(imei);
        }

        detalleVentaRepository.deleteAll(detalles);
        ventaRepository.delete(venta);
    }

    private String generarNumeroVenta() {
        return "VTA-" + (ventaRepository.count() + 1);
    }

    private void validarDetalle(DetalleVentaDTO detalleDto) {
        if (detalleDto.getProductoId() == null) {
            throw new RuntimeException("Debe seleccionar un producto");
        }

        if (detalleDto.getCantidad() == null || detalleDto.getCantidad() <= 0) {
            throw new RuntimeException("La cantidad debe ser mayor a cero");
        }

        if (detalleDto.getPrecioUnitario() == null || detalleDto.getPrecioUnitario() <= 0) {
            throw new RuntimeException("El precio unitario debe ser mayor a cero");
        }
    }

    private List<IMEI> obtenerImeisParaVenta(DetalleVentaDTO detalleDto, Producto producto) {
        if (detalleDto.getImeiId() != null) {
            IMEI imei = imeiRepository.findById(detalleDto.getImeiId())
                    .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
            if (imei.getEstado() != IMEI.EstadoIMEI.EN_STOCK) {
                throw new RuntimeException("El IMEI seleccionado no esta disponible");
            }
            return List.of(imei);
        }

        imeiService.listarPorProducto(producto.getId());
        List<IMEI> disponibles = imeiRepository
                .findByProductoIdAndEstado(producto.getId(), IMEI.EstadoIMEI.EN_STOCK)
                .stream()
                .limit(detalleDto.getCantidad())
                .toList();

        if (disponibles.size() < detalleDto.getCantidad()) {
            throw new RuntimeException("Stock insuficiente para " + producto.getNombre() + ". Disponible: " + disponibles.size());
        }

        return disponibles;
    }

    private VentaDTO convertirADTO(Venta venta) {
        return VentaDTO.builder()
                .id(venta.getId())
                .numeroVenta(venta.getNumeroVenta())
                .clienteId(venta.getCliente().getId())
                .clienteNombre(venta.getCliente().getNombre() + " " + venta.getCliente().getApellido())
                .total(venta.getTotal())
                .estado(venta.getEstado().toString())
                .fechaVenta(venta.getFechaVenta())
                .build();
    }

    private DetalleVentaDTO convertirDetalleADTO(DetalleVenta detalle) {
        return DetalleVentaDTO.builder()
                .id(detalle.getId())
                .ventaId(detalle.getVenta().getId())
                .productoId(detalle.getProducto().getId())
                .productoNombre(detalle.getProducto().getNombre())
                .cantidad(1)
                .imeiId(detalle.getImei().getId())
                .imeiNumero(detalle.getImei().getNumero())
                .precioUnitario(detalle.getPrecioUnitario())
                .subtotal(detalle.getSubtotal())
                .build();
    }
}
