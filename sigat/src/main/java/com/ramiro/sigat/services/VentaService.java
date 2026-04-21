package com.ramiro.sigat.services;
import com.ramiro.sigat.models.*;
import com.ramiro.sigat.repositories.*;
import com.ramiro.sigat.dto.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.stream.Collectors;
import java.time.LocalDateTime;
@Service
public class VentaService {
    @Autowired
    private VentaRepository ventaRepository;
    @Autowired
    private DetalleVentaRepository detalleVentaRepository;
    @Autowired
    private ClienteRepository clienteRepository;
    @Autowired
    private ProductoRepository productoRepository;
    @Autowired
    private IMEIRepository imeiRepository;
    public VentaDTO crearVenta(VentaDTO dto, List<DetalleVentaDTO> detalles) {
        Cliente cliente = clienteRepository.findById(dto.getClienteId())
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));
        Venta venta = new Venta();
        venta.setNumeroVenta(generarNumeroVenta());
        venta.setCliente(cliente);
        venta.setEstado(Venta.EstadoVenta.COMPLETADA);
        venta.setTotal(0.0);
        venta = ventaRepository.save(venta);
        Double total = 0.0;
        for (DetalleVentaDTO detalleDto : detalles) {
            DetalleVenta detalle = new DetalleVenta();
            detalle.setVenta(venta);
            Producto producto = productoRepository.findById(detalleDto.getProductoId())
                    .orElseThrow(() -> new RuntimeException("Producto no encontrado"));
            detalle.setProducto(producto);
            IMEI imei = imeiRepository.findById(detalleDto.getImeiId())
                    .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
            detalle.setImei(imei);
            detalle.setPrecioUnitario(detalleDto.getPrecioUnitario());
            detalle.calcularSubtotal();
            detalleVentaRepository.save(detalle);
            total += detalle.getSubtotal();
            // Actualizar IMEI
            imei.setEstado(IMEI.EstadoIMEI.VENDIDO);
            imei.setClienteId(cliente.getId());
            imei.setFechaVenta(LocalDateTime.now());
            imeiRepository.save(imei);
            // Descontar stock del producto
            producto.setStockActual(producto.getStockActual() - 1);
            productoRepository.save(producto);
        }
        venta.setTotal(total);
        venta = ventaRepository.save(venta);
        return convertirADTO(venta);
    }
    public VentaDTO obtenerPorId(Long id) {
        Venta venta = ventaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Venta no encontrada"));
        return convertirADTO(venta);
    }
    public List<VentaDTO> listarTodas() {
        return ventaRepository.findAll().stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public List<VentaDTO> listarPorCliente(Long clienteId) {
        return ventaRepository.findByClienteId(clienteId).stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public List<DetalleVentaDTO> obtenerDetalles(Long ventaId) {
        return detalleVentaRepository.findByVentaId(ventaId).stream()
                .map(this::convertirDetalleADTO)
                .collect(Collectors.toList());
    }
    private String generarNumeroVenta() {
        Long ultimaVenta = ventaRepository.count();
        return "VTA-" + (ultimaVenta + 1);
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
                .imeiId(detalle.getImei().getId())
                .imeiNumero(detalle.getImei().getNumero())
                .precioUnitario(detalle.getPrecioUnitario())
                .subtotal(detalle.getSubtotal())
                .build();
    }
}