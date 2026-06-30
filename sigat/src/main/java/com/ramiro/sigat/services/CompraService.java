package com.ramiro.sigat.services;

import com.ramiro.sigat.exceptions.ResourceNotFoundException;

import com.ramiro.sigat.dto.CompraConDetallesDTO;
import com.ramiro.sigat.dto.CompraDTO;
import com.ramiro.sigat.dto.DetalleCompraDTO;
import com.ramiro.sigat.dto.IMEIDTO;
import com.ramiro.sigat.models.Cliente;
import com.ramiro.sigat.models.Compra;
import com.ramiro.sigat.models.DetalleCompra;
import com.ramiro.sigat.models.IMEI;
import com.ramiro.sigat.models.Producto;
import com.ramiro.sigat.models.Proveedor;
import com.ramiro.sigat.models.Venta;
import com.ramiro.sigat.repositories.CompraRepository;
import com.ramiro.sigat.repositories.DetalleCompraRepository;
import com.ramiro.sigat.repositories.IMEIRepository;
import com.ramiro.sigat.repositories.ProductoRepository;
import com.ramiro.sigat.repositories.ProveedorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class CompraService {
    private final CompraRepository compraRepository;
    private final DetalleCompraRepository detalleCompraRepository;
    private final ProveedorRepository proveedorRepository;
    private final ProductoRepository productoRepository;
    private final IMEIRepository imeiRepository;
    private final AtomicLong contadorCompra;

    public CompraService(
            CompraRepository compraRepository,
            DetalleCompraRepository detalleCompraRepository,
            ProveedorRepository proveedorRepository,
            ProductoRepository productoRepository,
            IMEIRepository imeiRepository
    ) {
        this.compraRepository = compraRepository;
        this.detalleCompraRepository = detalleCompraRepository;
        this.proveedorRepository = proveedorRepository;
        this.productoRepository = productoRepository;
        this.imeiRepository = imeiRepository;
        this.contadorCompra = new AtomicLong(compraRepository.count());
    }

    @Transactional
    public CompraDTO crearCompra(CompraDTO dto, List<DetalleCompraDTO> detalles) {
        if (detalles == null || detalles.isEmpty()) {
            throw new RuntimeException("La compra debe tener al menos un detalle");
        }

        Proveedor proveedor = proveedorRepository.findById(dto.getProveedorId())
                .orElseThrow(() -> new ResourceNotFoundException("Proveedor no encontrado"));

        Compra compra = new Compra();
        compra.setTipoComprobante(dto.getTipoComprobante());
        compra.setNumeroCompra(generarNumeroCompra(dto.getTipoComprobante()));
        compra.setProveedor(proveedor);
        compra.setEstado(Compra.EstadoCompra.PENDIENTE);
        compra.setTotal(0.0);
        compra = compraRepository.save(compra);

        double total = 0.0;
        Set<String> imeisCompra = new HashSet<>();

        for (DetalleCompraDTO detalleDto : detalles) {
            validarDetalle(detalleDto);

            Producto producto = productoRepository.findById(detalleDto.getProductoId())
                    .orElseThrow(() -> new ResourceNotFoundException("Producto no encontrado"));

            DetalleCompra detalle = new DetalleCompra();
            detalle.setCompra(compra);
            detalle.setProducto(producto);
            detalle.setCantidad(detalleDto.getCantidad());
            detalle.setPrecioUnitario(detalleDto.getPrecioUnitario());
            detalle.calcularSubtotal();
            detalleCompraRepository.save(detalle);

            total += detalle.getSubtotal();

            for (String numeroImei : generarImeis(detalleDto.getCantidad(), imeisCompra)) {
                IMEI imei = new IMEI();
                imei.setNumero(numeroImei);
                imei.setProducto(producto);
                imei.setCompra(compra);
                imei.setDetalleCompra(detalle);
                imei.setEstado(IMEI.EstadoIMEI.EN_STOCK);
                imeiRepository.save(imei);
            }

            producto.setStockActual(producto.getStockActual() + detalleDto.getCantidad());
            productoRepository.save(producto);
        }

        compra.setTotal(total);
        compra.setEstado(Compra.EstadoCompra.RECIBIDA);
        return convertirADTO(compraRepository.save(compra));
    }

    @Transactional(readOnly = true)
    public CompraDTO obtenerPorId(Long id) {
        Compra compra = compraRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Compra no encontrada"));
        return convertirADTO(compra);
    }

    @Transactional(readOnly = true)
    public List<CompraDTO> listarTodas() {
        return compraRepository.findAll().stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CompraDTO> listarPorProveedor(Long proveedorId) {
        return compraRepository.findByProveedorId(proveedorId).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<DetalleCompraDTO> obtenerDetalles(Long compraId) {
        return detalleCompraRepository.findByCompraId(compraId).stream()
                .map(this::convertirDetalleADTO)
                .toList();
    }

    /**
     * Igual que listarTodas(), pero incluye el detalle de cada compra en la
     * misma respuesta para que un cliente de reportes no tenga que pedir
     * el detalle compra por compra (evita N+1 peticiones HTTP).
     */
    @Transactional(readOnly = true)
    public List<CompraConDetallesDTO> listarTodasConDetalles() {
        return compraRepository.findAll().stream()
                .map(compra -> CompraConDetallesDTO.builder()
                        .compra(convertirADTO(compra))
                        .detalles(obtenerDetalles(compra.getId()))
                        .build())
                .toList();
    }

    @Transactional
    public void eliminar(Long compraId) {
        Compra compra = compraRepository.findById(compraId)
                .orElseThrow(() -> new ResourceNotFoundException("Compra no encontrada"));
        List<IMEI> imeis = imeiRepository.findByCompraId(compraId);

        boolean tieneImeisVendidos = imeis.stream()
                .anyMatch(imei -> imei.getEstado() == IMEI.EstadoIMEI.VENDIDO);
        if (tieneImeisVendidos) {
            throw new RuntimeException("No se puede eliminar la compra porque tiene IMEI vendidos");
        }

        List<DetalleCompra> detalles = detalleCompraRepository.findByCompraId(compraId);
        for (DetalleCompra detalle : detalles) {
            Producto producto = detalle.getProducto();
            int stockActual = producto.getStockActual() == null ? 0 : producto.getStockActual();
            producto.setStockActual(Math.max(0, stockActual - detalle.getCantidad()));
            productoRepository.save(producto);
        }

        imeiRepository.deleteAll(imeis);
        detalleCompraRepository.deleteAll(detalles);
        compraRepository.delete(compra);
    }

    /**
     * Numero atomico en memoria: dos compras concurrentes nunca obtienen el
     * mismo valor (a diferencia de leer count()+1, que es una condicion de
     * carrera entre el SELECT y el INSERT de cada transaccion).
     */
    private String generarNumeroCompra(String tipo) {
        long n = contadorCompra.incrementAndGet();
        if (tipo == null || tipo.isBlank()) return "CMP-" + n;
        return switch (tipo.toUpperCase()) {
            case "BOLETA"  -> String.format("B001-%06d", n);
            case "FACTURA" -> String.format("F001-%06d", n);
            case "GUIA"    -> String.format("G001-%06d", n);
            default        -> "CMP-" + n;
        };
    }

    private void validarDetalle(DetalleCompraDTO detalleDto) {
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
                        .toList())
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
                .tipoComprobante(compra.getTipoComprobante())
                .proveedorId(compra.getProveedor().getId())
                .proveedorNombre(compra.getProveedor().getNombre())
                .total(compra.getTotal())
                .estado(compra.getEstado().toString())
                .fechaCompra(compra.getFechaCompra())
                .build();
    }
}
