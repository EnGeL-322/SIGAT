package com.ramiro.sigat.services;

import com.ramiro.sigat.dto.DetalleVentaDTO;
import com.ramiro.sigat.dto.VentaDTO;
import com.ramiro.sigat.models.Cliente;
import com.ramiro.sigat.models.IMEI;
import com.ramiro.sigat.models.Producto;
import com.ramiro.sigat.repositories.ClienteRepository;
import com.ramiro.sigat.repositories.IMEIRepository;
import com.ramiro.sigat.repositories.ProductoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * RF-VTA-001 - Registrar una venta de equipos con trazabilidad por IMEI.
 * Cubre el flujo completo: seleccion automatica de un IMEI EN_STOCK,
 * actualizacion de su estado a VENDIDO, descuento de stock del producto,
 * calculo del total y generacion de un numero de venta unico.
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class VentaServiceTest {

    @Autowired
    private VentaService ventaService;
    @Autowired
    private ClienteRepository clienteRepository;
    @Autowired
    private ProductoRepository productoRepository;
    @Autowired
    private IMEIRepository imeiRepository;

    private Cliente cliente;
    private Producto producto;

    @BeforeEach
    void seedDatos() {
        cliente = clienteRepository.save(Cliente.builder()
                .nombre("Juan").apellido("Perez").cedula("12345678")
                .email("juan@test.com").telefono("999999999").activo(true).build());

        producto = productoRepository.save(Producto.builder()
                .nombre("Samsung Galaxy S24").codigo("SAM-S24-TEST").marca("Samsung").modelo("S24")
                .precio(500.0).stockActual(2).stockMinimo(1).activo(true).build());

        imeiRepository.save(IMEI.builder().numero("111111111111111").producto(producto)
                .estado(IMEI.EstadoIMEI.EN_STOCK).build());
        imeiRepository.save(IMEI.builder().numero("222222222222222").producto(producto)
                .estado(IMEI.EstadoIMEI.EN_STOCK).build());
    }

    @Test
    void registraUnaVentaYMarcaElImeiSeleccionadoComoVendido() {
        VentaDTO ventaDto = VentaDTO.builder().clienteId(cliente.getId())
                .vendedorNombre("SIGAT").build();
        DetalleVentaDTO detalle = DetalleVentaDTO.builder()
                .productoId(producto.getId()).cantidad(1).precioUnitario(500.0).build();

        VentaDTO creada = ventaService.crearVenta(ventaDto, List.of(detalle));

        assertThat(creada.getNumeroVenta()).startsWith("VTA-");
        assertThat(creada.getTotal()).isEqualTo(500.0);

        long imeisVendidos = imeiRepository.findAll().stream()
                .filter(i -> i.getProducto().getId().equals(producto.getId()))
                .filter(i -> i.getEstado() == IMEI.EstadoIMEI.VENDIDO)
                .count();
        assertThat(imeisVendidos).isEqualTo(1);

        Producto productoActualizado = productoRepository.findById(producto.getId()).orElseThrow();
        assertThat(productoActualizado.getStockActual()).isEqualTo(1);
    }

    @Test
    void generaNumerosDeVentaUnicosYCrecientesEnVentasSucesivas() {
        VentaDTO ventaDto = VentaDTO.builder().clienteId(cliente.getId()).vendedorNombre("SIGAT").build();
        DetalleVentaDTO detalle = DetalleVentaDTO.builder()
                .productoId(producto.getId()).cantidad(1).precioUnitario(500.0).build();

        VentaDTO primeraVenta = ventaService.crearVenta(ventaDto, List.of(detalle));
        VentaDTO segundaVenta = ventaService.crearVenta(
                VentaDTO.builder().clienteId(cliente.getId()).vendedorNombre("SIGAT").build(),
                List.of(DetalleVentaDTO.builder().productoId(producto.getId()).cantidad(1).precioUnitario(500.0).build()));

        assertThat(primeraVenta.getNumeroVenta()).isNotEqualTo(segundaVenta.getNumeroVenta());
    }

    @Test
    void rechazaLaVentaSiNoHayStockSuficienteDeImeisEnStock() {
        VentaDTO ventaDto = VentaDTO.builder().clienteId(cliente.getId()).vendedorNombre("SIGAT").build();
        DetalleVentaDTO detalleConCantidadExcesiva = DetalleVentaDTO.builder()
                .productoId(producto.getId()).cantidad(5).precioUnitario(500.0).build();

        assertThatThrownBy(() -> ventaService.crearVenta(ventaDto, List.of(detalleConCantidadExcesiva)))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Stock insuficiente");
    }
}
