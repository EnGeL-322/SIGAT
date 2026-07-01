package com.ramiro.sigat.config;

import com.ramiro.sigat.dto.CompraDTO;
import com.ramiro.sigat.dto.DetalleCompraDTO;
import com.ramiro.sigat.dto.DetalleVentaDTO;
import com.ramiro.sigat.dto.VentaDTO;
import com.ramiro.sigat.models.Cliente;
import com.ramiro.sigat.models.Producto;
import com.ramiro.sigat.models.Proveedor;
import com.ramiro.sigat.repositories.ClienteRepository;
import com.ramiro.sigat.repositories.CompraRepository;
import com.ramiro.sigat.repositories.ProductoRepository;
import com.ramiro.sigat.repositories.ProveedorRepository;
import com.ramiro.sigat.services.CompraService;
import com.ramiro.sigat.services.VentaService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final CompraService compraService;
    private final VentaService ventaService;
    private final ClienteRepository clienteRepository;
    private final ProveedorRepository proveedorRepository;
    private final ProductoRepository productoRepository;
    private final CompraRepository compraRepository;

    @Override
    public void run(String... args) {
        if (compraRepository.count() > 0) {
            log.info("[DataInitializer] Ya existen datos, se omite la inicializacion.");
            return;
        }

        log.info("[DataInitializer] Poblando la base de datos con datos de ejemplo...");

        List<Proveedor> proveedores = crearProveedores();
        List<Cliente>   clientes    = crearClientes();
        List<Producto>  productos   = crearProductos();

        crearCompras(proveedores, productos);
        crearVentas(clientes, productos);

        log.info("[DataInitializer] Datos de ejemplo creados exitosamente.");
    }

    // ── Proveedores ─────────────────────────────────────────────────────────

    private List<Proveedor> crearProveedores() {
        if (proveedorRepository.count() > 0) return proveedorRepository.findAll();

        return proveedorRepository.saveAll(List.of(
            Proveedor.builder()
                .nombre("Distribuidora TechPhone")
                .ruc("20601234567")
                .email("ventas@techphone.pe")
                .telefono("01-2345678")
                .direccion("Av. Wilson 1234, Lima")
                .contacto("Jorge Paredes")
                .activo(true).build(),

            Proveedor.builder()
                .nombre("Samsung Peru SAC")
                .ruc("20602345678")
                .email("distribuidores@samsung.pe")
                .telefono("01-3456789")
                .direccion("Av. Javier Prado 456, San Isidro")
                .contacto("Lucia Romero")
                .activo(true).build(),

            Proveedor.builder()
                .nombre("ImportMovil Pro")
                .ruc("20603456789")
                .email("info@importmovilpro.com")
                .telefono("01-4567890")
                .direccion("Jr. Gamarra 789, La Victoria")
                .contacto("Roberto Flores")
                .activo(true).build()
        ));
    }

    // ── Clientes ─────────────────────────────────────────────────────────────

    private List<Cliente> crearClientes() {
        if (clienteRepository.count() > 0) return clienteRepository.findAll();

        return clienteRepository.saveAll(List.of(
            Cliente.builder()
                .nombre("Carlos").apellido("Mendoza")
                .cedula("12345678").email("cmendoza@gmail.com")
                .telefono("987654321").direccion("Av. Brasil 123, Breña")
                .activo(true).build(),

            Cliente.builder()
                .nombre("Maria").apellido("Torres")
                .cedula("23456789").email("maria.torres@hotmail.com")
                .telefono("976543210").direccion("Jr. Tacna 456, Lima Centro")
                .activo(true).build(),

            Cliente.builder()
                .nombre("Luis").apellido("Garcia")
                .cedula("34567890").email("lgarcia@yahoo.com")
                .telefono("965432109").direccion("Calle Los Rosales 789, Surco")
                .activo(true).build(),

            Cliente.builder()
                .nombre("Ana").apellido("Rodriguez")
                .cedula("45678901").email("arodriguez@gmail.com")
                .telefono("954321098").direccion("Av. Primavera 234, San Borja")
                .activo(true).build(),

            Cliente.builder()
                .nombre("Pedro").apellido("Villanueva")
                .cedula("56789012").email("pvillanueva@outlook.com")
                .telefono("943210987").direccion("Av. Arequipa 567, Miraflores")
                .activo(true).build()
        ));
    }

    // ── Productos ─────────────────────────────────────────────────────────────

    private List<Producto> crearProductos() {
        if (productoRepository.count() > 0) return productoRepository.findAll();

        return productoRepository.saveAll(List.of(
            Producto.builder()
                .nombre("Samsung Galaxy A15").codigo("SAM-A15-BLK")
                .marca("Samsung").modelo("Galaxy A15")
                .memoria("128GB").ram("4GB").color("Negro")
                .precio(699.0).stockActual(0).stockMinimo(5).activo(true)
                .descripcion("Pantalla Super AMOLED 6.5\" | Camara triple 50MP").build(),

            Producto.builder()
                .nombre("Samsung Galaxy A35").codigo("SAM-A35-AZL")
                .marca("Samsung").modelo("Galaxy A35")
                .memoria("256GB").ram("8GB").color("Azul Oscuro")
                .precio(1299.0).stockActual(0).stockMinimo(5).activo(true)
                .descripcion("Pantalla Super AMOLED+ 6.6\" | Camara 50MP OIS").build(),

            Producto.builder()
                .nombre("iPhone 15 Standard").codigo("APL-IP15-NGR")
                .marca("Apple").modelo("iPhone 15")
                .memoria("128GB").ram("6GB").color("Negro")
                .precio(3899.0).stockActual(0).stockMinimo(3).activo(true)
                .descripcion("Chip A16 Bionic | Pantalla OLED 6.1\"").build(),

            Producto.builder()
                .nombre("Xiaomi Redmi Note 13").codigo("XIA-RN13-GRS")
                .marca("Xiaomi").modelo("Redmi Note 13")
                .memoria("256GB").ram("8GB").color("Gris Medianoche")
                .precio(799.0).stockActual(0).stockMinimo(5).activo(true)
                .descripcion("Pantalla AMOLED 6.67\" 120Hz | Camara 108MP").build(),

            Producto.builder()
                .nombre("Motorola Moto G84").codigo("MOT-G84-MGT")
                .marca("Motorola").modelo("Moto G84")
                .memoria("256GB").ram("12GB").color("Magenta")
                .precio(899.0).stockActual(0).stockMinimo(5).activo(true)
                .descripcion("Pantalla pOLED 6.55\" 144Hz | Bateria 5000mAh").build()
        ));
    }

    // ── Compras ──────────────────────────────────────────────────────────────
    // 8 compras → genera IMEIs automaticamente y sube el stock de cada producto.

    private void crearCompras(List<Proveedor> proveedores, List<Producto> productos) {
        Long prov1 = proveedores.get(0).getId();
        Long prov2 = proveedores.get(1).getId();
        Long prov3 = proveedores.get(2).getId();

        Long samA15  = productos.get(0).getId();
        Long samA35  = productos.get(1).getId();
        Long ip15    = productos.get(2).getId();
        Long xRN13   = productos.get(3).getId();
        Long motoG84 = productos.get(4).getId();

        // { proveedorId, tipo, productoId, cantidad, precioCompra }
        Object[][] datos = {
            { prov1, "BOLETA",  samA15,  5, 420.0  },
            { prov2, "FACTURA", samA35,  3, 780.0  },
            { prov1, "FACTURA", ip15,    2, 2500.0 },
            { prov3, "GUIA",    xRN13,   4, 450.0  },
            { prov2, "BOLETA",  motoG84, 6, 520.0  },
            { prov1, "GUIA",    samA15,  3, 425.0  },
            { prov3, "FACTURA", samA35,  2, 790.0  },
            { prov2, "BOLETA",  xRN13,   4, 455.0  },
        };

        for (Object[] d : datos) {
            try {
                compraService.crearCompra(
                    CompraDTO.builder()
                        .proveedorId((Long) d[0])
                        .tipoComprobante((String) d[1])
                        .build(),
                    List.of(DetalleCompraDTO.builder()
                        .productoId((Long) d[2])
                        .cantidad((Integer) d[3])
                        .precioUnitario((Double) d[4])
                        .build())
                );
            } catch (Exception e) {
                log.warn("[DataInitializer] No se pudo crear compra: {}", e.getMessage());
            }
        }
    }

    // ── Ventas ───────────────────────────────────────────────────────────────
    // 10 ventas → usa IMEIs disponibles del stock (asignacion automatica).

    private void crearVentas(List<Cliente> clientes, List<Producto> productos) {
        Long cli1 = clientes.get(0).getId();
        Long cli2 = clientes.get(1).getId();
        Long cli3 = clientes.get(2).getId();
        Long cli4 = clientes.get(3).getId();
        Long cli5 = clientes.get(4).getId();

        Long samA15  = productos.get(0).getId();
        Long samA35  = productos.get(1).getId();
        Long ip15    = productos.get(2).getId();
        Long xRN13   = productos.get(3).getId();
        Long motoG84 = productos.get(4).getId();

        // { clienteId, tipo, productoId, cantidad, precioVenta }
        Object[][] datos = {
            { cli1, "BOLETA",  samA15,  1, 699.0  },
            { cli2, "FACTURA", ip15,    1, 3899.0 },
            { cli3, "BOLETA",  samA35,  1, 1299.0 },
            { cli4, "BOLETA",  xRN13,   2, 799.0  },
            { cli5, "BOLETA",  motoG84, 1, 899.0  },
            { cli1, "FACTURA", samA15,  1, 699.0  },
            { cli2, "BOLETA",  samA35,  1, 1299.0 },
            { cli3, "FACTURA", motoG84, 1, 899.0  },
            { cli4, "BOLETA",  xRN13,   1, 799.0  },
            { cli5, "BOLETA",  motoG84, 2, 899.0  },
        };

        for (Object[] d : datos) {
            try {
                ventaService.crearVenta(
                    VentaDTO.builder()
                        .clienteId((Long) d[0])
                        .tipoComprobante((String) d[1])
                        .vendedorNombre("SIGAT")
                        .build(),
                    List.of(DetalleVentaDTO.builder()
                        .productoId((Long) d[2])
                        .cantidad((Integer) d[3])
                        .precioUnitario((Double) d[4])
                        .build())
                );
            } catch (Exception e) {
                log.warn("[DataInitializer] No se pudo crear venta: {}", e.getMessage());
            }
        }
    }
}
