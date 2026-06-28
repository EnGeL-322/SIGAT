package com.ramiro.sigat.services;

import com.ramiro.sigat.dto.CompraDTO;
import com.ramiro.sigat.dto.DetalleCompraDTO;
import com.ramiro.sigat.models.IMEI;
import com.ramiro.sigat.models.Producto;
import com.ramiro.sigat.models.Proveedor;
import com.ramiro.sigat.repositories.IMEIRepository;
import com.ramiro.sigat.repositories.ProductoRepository;
import com.ramiro.sigat.repositories.ProveedorRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RF-CMP-001 - Registrar una compra de equipos y actualizar el inventario.
 * Cubre el flujo completo: creacion de la cabecera de compra con un numero
 * unico, generacion de un IMEI por cada unidad comprada (estado EN_STOCK)
 * y el incremento del stock del producto involucrado.
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class CompraServiceTest {

    @Autowired
    private CompraService compraService;
    @Autowired
    private ProveedorRepository proveedorRepository;
    @Autowired
    private ProductoRepository productoRepository;
    @Autowired
    private IMEIRepository imeiRepository;

    private Proveedor proveedor;
    private Producto producto;

    @BeforeEach
    void seedDatos() {
        proveedor = proveedorRepository.save(Proveedor.builder()
                .nombre("Importaciones Test S.A.C.").ruc("20999999999")
                .email("ventas@test.com").telefono("999999999").activo(true).build());

        producto = productoRepository.save(Producto.builder()
                .nombre("Xiaomi Redmi Note 13").codigo("XIA-RN13-TEST").marca("Xiaomi").modelo("Redmi Note 13")
                .precio(300.0).stockActual(0).stockMinimo(5).activo(true).build());
    }

    @Test
    void registraUnaCompraYGeneraUnImeiEnStockPorCadaUnidad() {
        CompraDTO compraDto = CompraDTO.builder().proveedorId(proveedor.getId()).build();
        DetalleCompraDTO detalle = DetalleCompraDTO.builder()
                .productoId(producto.getId()).cantidad(3).precioUnitario(300.0).build();

        CompraDTO creada = compraService.crearCompra(compraDto, List.of(detalle));

        assertThat(creada.getNumeroCompra()).startsWith("CMP-");
        assertThat(creada.getTotal()).isEqualTo(900.0);
        assertThat(creada.getEstado()).isEqualTo("RECIBIDA");

        List<IMEI> imeisDelProducto = imeiRepository.findAll().stream()
                .filter(i -> i.getProducto().getId().equals(producto.getId()))
                .toList();
        assertThat(imeisDelProducto).hasSize(3);
        assertThat(imeisDelProducto).allMatch(i -> i.getEstado() == IMEI.EstadoIMEI.EN_STOCK);
        assertThat(imeisDelProducto).extracting(IMEI::getNumero).doesNotHaveDuplicates();

        Producto productoActualizado = productoRepository.findById(producto.getId()).orElseThrow();
        assertThat(productoActualizado.getStockActual()).isEqualTo(3);
    }

    @Test
    void generaNumerosDeCompraUnicosEnComprasSucesivas() {
        DetalleCompraDTO detalle = DetalleCompraDTO.builder()
                .productoId(producto.getId()).cantidad(1).precioUnitario(300.0).build();

        CompraDTO primeraCompra = compraService.crearCompra(
                CompraDTO.builder().proveedorId(proveedor.getId()).build(), List.of(detalle));
        CompraDTO segundaCompra = compraService.crearCompra(
                CompraDTO.builder().proveedorId(proveedor.getId()).build(),
                List.of(DetalleCompraDTO.builder().productoId(producto.getId()).cantidad(1).precioUnitario(300.0).build()));

        assertThat(primeraCompra.getNumeroCompra()).isNotEqualTo(segundaCompra.getNumeroCompra());
    }
}
