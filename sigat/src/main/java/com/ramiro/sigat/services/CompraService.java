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
    public CompraDTO crearCompra(CompraDTO dto, List<DetalleCompraDTO> detalles) {
        Proveedor proveedor = proveedorRepository.findById(dto.getProveedorId())
                .orElseThrow(() -> new RuntimeException("Proveedor no encontrado"));
        Compra compra = new Compra();
        compra.setNumeroCompra(generarNumeroCompra());
        compra.setProveedor(proveedor);
        compra.setEstado(Compra.EstadoCompra.PENDIENTE);
        compra.setTotal(0.0);
        compra = compraRepository.save(compra);
        Double total = 0.0;
        for (DetalleCompraDTO detalleDto : detalles) {
            DetalleCompra detalle = new DetalleCompra();
            detalle.setCompra(compra);
            Producto producto = productoRepository.findById(detalleDto.getProductoId())
                    .orElseThrow(() -> new RuntimeException("Producto no encontrado"));
            detalle.setProducto(producto);
            detalle.setCantidad(detalleDto.getCantidad());
            detalle.setPrecioUnitario(detalleDto.getPrecioUnitario());
            detalle.calcularSubtotal();
            detalleCompraRepository.save(detalle);
            total += detalle.getSubtotal();
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
    private String generarNumeroCompra() {
        Long ultimaCompra = compraRepository.count();
        return "CMP-" + (ultimaCompra + 1);
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