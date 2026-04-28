package com.ramiro.sigat.services;

import com.ramiro.sigat.models.*;
import com.ramiro.sigat.repositories.*;
import com.ramiro.sigat.dto.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;
@Service
public class CompraService {
    @Autowired
    private CompraRepository compraRepository;
    @Autowired
    private DetalleCompraRepository detalleCompraRepository;
    @Autowired
    private ProveedorRepository proveedorRepository;
    @Autowired
    private ProductoRepository productoRepository;
    @Autowired
    private IMEIRepository imeiRepository;

    @Transactional
    public CompraDTO crearCompra(CompraDTO dto, List<DetalleCompraDTO> detalles) {
        if (detalles == null || detalles.isEmpty()) {
            throw new RuntimeException("La compra debe tener al menos un detalle");
        }

        Proveedor proveedor = proveedorRepository.findById(dto.getProveedorId())
                .orElseThrow(() -> new RuntimeException("Proveedor no encontrado"));
        Compra compra = new Compra();
        compra.setNumeroCompra(generarNumeroCompra());
        compra.setProveedor(proveedor);
        compra.setEstado(Compra.EstadoCompra.PENDIENTE);
        compra.setTotal(0.0);
        compra = compraRepository.save(compra);
        Double total = 0.0;
        Set<String> imeisCompra = new HashSet<>();
        for (DetalleCompraDTO detalleDto : detalles) {
            DetalleCompra detalle = new DetalleCompra();
            detalle.setCompra(compra);
            Producto producto = productoRepository.findById(detalleDto.getProductoId())
                    .orElseThrow(() -> new RuntimeException("Producto no encontrado"));
            validarDetalle(detalleDto);
            List<String> imeis = generarImeis(detalleDto.getCantidad(), imeisCompra);
            detalle.setProducto(producto);
            detalle.setCantidad(detalleDto.getCantidad());
            detalle.setPrecioUnitario(detalleDto.getPrecioUnitario());
            detalle.calcularSubtotal();
            detalleCompraRepository.save(detalle);
            total += detalle.getSubtotal();
            for (String numeroImei : imeis) {
                IMEI imei = new IMEI();
                imei.setNumero(numeroImei);
                imei.setProducto(producto);
                imei.setCompra(compra);
                imei.setDetalleCompra(detalle);
                imei.setEstado(IMEI.EstadoIMEI.EN_STOCK);
                imeiRepository.save(imei);
            }
            // Actualizar stock del producto
            producto.setStockActual(producto.getStockActual() + detalleDto.getCantidad());
            productoRepository.save(producto);
        }
        compra.setTotal(total);
        compra.setEstado(Compra.EstadoCompra.RECIBIDA);
        compra = compraRepository.save(compra);
        return convertirADTO(compra);
    }
    public CompraDTO obtenerPorId(Long id) {
        Compra compra = compraRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Compra no encontrada"));
        return convertirADTO(compra);
    }
    public List<CompraDTO> listarTodas() {
        return compraRepository.findAll().stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public List<CompraDTO> listarPorProveedor(Long proveedorId) {
        return compraRepository.findByProveedorId(proveedorId).stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }

    public List<DetalleCompraDTO> obtenerDetalles(Long compraId) {
        return detalleCompraRepository.findByCompraId(compraId).stream()
                .map(this::convertirDetalleADTO)
                .collect(Collectors.toList());
    }
    private String generarNumeroCompra() {
        Long ultimaCompra = compraRepository.count();
        return "CMP-" + (ultimaCompra + 1);
    }
    private void validarDetalle(DetalleCompraDTO detalleDto) {
        if (detalleDto.getCantidad() == null || detalleDto.getCantidad() <= 0) {
            throw new RuntimeException("La cantidad debe ser mayor a cero");
        }

        if (detalleDto.getPrecioUnitario() == null || detalleDto.getPrecioUnitario() <= 0) {
            throw new RuntimeException("El precio unitario debe ser mayor a cero");
        }
    }

    private List<String> generarImeis(Integer cantidad, Set<String> imeisCompra) {
        List<String> imeis = new ArrayList<>();
        while (imeis.size() < cantidad) {
            String imei = generarImei();
            if (imeisCompra.add(imei) && imeiRepository.findByNumero(imei).isEmpty()) {
                imeis.add(imei);
            }
        }
        return imeis;
    }

    private String generarImei() {
        String imei;
        do {
            imei = String.valueOf(100000000000000L + ThreadLocalRandom.current().nextLong(900000000000000L));
        } while (imeiRepository.findByNumero(imei).isPresent());
        return imei;
    }
    private DetalleCompraDTO convertirDetalleADTO(DetalleCompra detalle) {
        return DetalleCompraDTO.builder()
                .id(detalle.getId())
                .compraId(detalle.getCompra().getId())
                .productoId(detalle.getProducto().getId())
                .productoNombre(detalle.getProducto().getNombre())
                .cantidad(detalle.getCantidad())
                .precioUnitario(detalle.getPrecioUnitario())
                .subtotal(detalle.getSubtotal())
                .imeis(imeiRepository.findByDetalleCompraId(detalle.getId()).stream()
                        .map(this::convertirImeiADTO)
                        .collect(Collectors.toList()))
                .build();
    }

    private IMEIDTO convertirImeiADTO(IMEI imei) {
        Compra compra = imei.getCompra();
        Proveedor proveedor = compra != null ? compra.getProveedor() : null;
        Venta venta = imei.getVenta();
        Cliente cliente = venta != null ? venta.getCliente() : null;

        return IMEIDTO.builder()
                .id(imei.getId())
                .numero(imei.getNumero())
                .productoId(imei.getProducto().getId())
                .productoNombre(imei.getProducto().getNombre())
                .estado(imei.getEstado().toString())
                .compraId(compra != null ? compra.getId() : null)
                .numeroCompra(compra != null ? compra.getNumeroCompra() : null)
                .proveedorId(proveedor != null ? proveedor.getId() : null)
                .proveedorNombre(proveedor != null ? proveedor.getNombre() : null)
                .fechaIngreso(imei.getFechaIngreso())
                .ventaId(venta != null ? venta.getId() : null)
                .numeroVenta(venta != null ? venta.getNumeroVenta() : null)
                .clienteId(imei.getClienteId())
                .clienteNombre(cliente != null ? cliente.getNombre() + " " + cliente.getApellido() : null)
                .fechaVenta(imei.getFechaVenta())
                .build();
    }

    private CompraDTO convertirADTO(Compra compra) {
        return CompraDTO.builder()
                .id(compra.getId())
                .numeroCompra(compra.getNumeroCompra())
                .proveedorId(compra.getProveedor().getId())
                .proveedorNombre(compra.getProveedor().getNombre())
                .total(compra.getTotal())
                .estado(compra.getEstado().toString())
                .fechaCompra(compra.getFechaCompra())
                .build();
    }
}
