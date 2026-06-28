package com.ramiro.sigat.services;

import com.ramiro.sigat.dto.DashboardStatsDTO;
import com.ramiro.sigat.repositories.ClienteRepository;
import com.ramiro.sigat.repositories.ProductoRepository;
import com.ramiro.sigat.repositories.ProveedorRepository;
import com.ramiro.sigat.repositories.VentaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Contadores agregados para el dashboard. Antes, tanto la app web como la
 * movil descargaban las listas completas de productos/proveedores/clientes/
 * ventas solo para calcular su tamano; aqui se piden directamente al motor
 * de base de datos con COUNT(*), sin traer ni mapear cada fila a DTO.
 */
@Service
public class DashboardService {
    private final ProductoRepository productoRepository;
    private final ProveedorRepository proveedorRepository;
    private final ClienteRepository clienteRepository;
    private final VentaRepository ventaRepository;

    public DashboardService(
            ProductoRepository productoRepository,
            ProveedorRepository proveedorRepository,
            ClienteRepository clienteRepository,
            VentaRepository ventaRepository
    ) {
        this.productoRepository = productoRepository;
        this.proveedorRepository = proveedorRepository;
        this.clienteRepository = clienteRepository;
        this.ventaRepository = ventaRepository;
    }

    @Transactional(readOnly = true)
    public DashboardStatsDTO obtenerEstadisticas() {
        return DashboardStatsDTO.builder()
                .productos(productoRepository.countByActivo(true))
                .proveedores(proveedorRepository.countByActivo(true))
                .clientes(clienteRepository.countByActivo(true))
                .ventas(ventaRepository.count())
                .build();
    }
}
