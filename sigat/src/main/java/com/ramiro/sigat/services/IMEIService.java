package com.ramiro.sigat.services;

import com.ramiro.sigat.dto.IMEIDTO;
import com.ramiro.sigat.models.Cliente;
import com.ramiro.sigat.models.Compra;
import com.ramiro.sigat.models.IMEI;
import com.ramiro.sigat.models.Producto;
import com.ramiro.sigat.models.Proveedor;
import com.ramiro.sigat.models.Venta;
import com.ramiro.sigat.repositories.IMEIRepository;
import com.ramiro.sigat.repositories.ProductoRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class IMEIService {
    private final IMEIRepository imeiRepository;
    private final ProductoRepository productoRepository;

    public IMEIService(IMEIRepository imeiRepository, ProductoRepository productoRepository) {
        this.imeiRepository = imeiRepository;
        this.productoRepository = productoRepository;
    }

    @Transactional
    public IMEIDTO crearIMEI(IMEIDTO dto) {
        if (imeiRepository.findByNumero(dto.getNumero()).isPresent()) {
            throw new RuntimeException("IMEI ya existe");
        }

        Producto producto = productoRepository.findById(dto.getProductoId())
                .orElseThrow(() -> new RuntimeException("Producto no encontrado"));

        IMEI imei = new IMEI();
        imei.setNumero(dto.getNumero());
        imei.setEstado(IMEI.EstadoIMEI.EN_STOCK);
        imei.setProducto(producto);
        return convertirADTO(imeiRepository.save(imei));
    }

    @Transactional(readOnly = true)
    public IMEIDTO obtenerPorId(Long id) {
        IMEI imei = imeiRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
        return convertirADTO(imei);
    }

    @Transactional(readOnly = true)
    public IMEIDTO obtenerPorNumero(String numero) {
        IMEI imei = imeiRepository.findByNumero(numero)
                .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
        return convertirADTO(imei);
    }

    @Transactional
    public List<IMEIDTO> listarTodos() {
        productoRepository.findAll().forEach(this::generarImeisFaltantes);
        return imeiRepository.findAll().stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional
    public List<IMEIDTO> listarPorProducto(Long productoId) {
        Producto producto = productoRepository.findById(productoId)
                .orElseThrow(() -> new RuntimeException("Producto no encontrado"));
        generarImeisFaltantes(producto);
        return imeiRepository.findByProductoId(productoId).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional
    public List<IMEIDTO> listarEnStock() {
        productoRepository.findAll().forEach(this::generarImeisFaltantes);
        return imeiRepository.findByEstado(IMEI.EstadoIMEI.EN_STOCK).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<IMEIDTO> listarVendidos() {
        return imeiRepository.findByEstado(IMEI.EstadoIMEI.VENDIDO).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<IMEIDTO> listarPorEstado(String estado) {
        IMEI.EstadoIMEI estadoEnum = IMEI.EstadoIMEI.valueOf(estado);
        return imeiRepository.findByEstado(estadoEnum).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional
    public IMEIDTO marcarVendido(Long id, Long clienteId) {
        IMEI imei = imeiRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
        imei.setEstado(IMEI.EstadoIMEI.VENDIDO);
        imei.setClienteId(clienteId);
        imei.setFechaVenta(LocalDateTime.now());
        return convertirADTO(imeiRepository.save(imei));
    }

    private void generarImeisFaltantes(Producto producto) {
        int stockActual = Optional.ofNullable(producto.getStockActual()).orElse(0);
        if (stockActual <= 0) {
            return;
        }

        int imeisEnStock = imeiRepository
                .findByProductoIdAndEstado(producto.getId(), IMEI.EstadoIMEI.EN_STOCK)
                .size();
        int faltantes = stockActual - imeisEnStock;

        for (int i = 0; i < faltantes; i++) {
            IMEI imei = new IMEI();
            imei.setNumero(generarNumeroImei());
            imei.setProducto(producto);
            imei.setEstado(IMEI.EstadoIMEI.EN_STOCK);
            imeiRepository.save(imei);
        }
    }

    private String generarNumeroImei() {
        String numero;
        do {
            numero = String.valueOf(100000000000000L + ThreadLocalRandom.current().nextLong(900000000000000L));
        } while (imeiRepository.findByNumero(numero).isPresent());
        return numero;
    }

    private IMEIDTO convertirADTO(IMEI imei) {
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
}
