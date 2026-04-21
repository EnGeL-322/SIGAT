package com.ramiro.sigat.services;

import com.ramiro.sigat.models.*;
import com.ramiro.sigat.repositories.*;
import com.ramiro.sigat.dto.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.stream.Collectors;
@Service
public class IMEIService {
    @Autowired
    private IMEIRepository imeiRepository;
    @Autowired
    private ProductoRepository productoRepository;
    public IMEIDTO crearIMEI(IMEIDTO dto) {
        if (imeiRepository.findByNumero(dto.getNumero()).isPresent()) {
            throw new RuntimeException("IMEI ya existe");
        }
        IMEI imei = new IMEI();
        imei.setNumero(dto.getNumero());
        imei.setEstado(IMEI.EstadoIMEI.EN_STOCK);
        Producto producto = productoRepository.findById(dto.getProductoId())
                .orElseThrow(() -> new RuntimeException("Producto no encontrado"));
        imei.setProducto(producto);
        imei = imeiRepository.save(imei);
        return convertirADTO(imei);
    }
    public IMEIDTO obtenerPorId(Long id) {
        IMEI imei = imeiRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
        return convertirADTO(imei);
    }
    public IMEIDTO obtenerPorNumero(String numero) {
        IMEI imei = imeiRepository.findByNumero(numero)
                .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
        return convertirADTO(imei);
    }
    public List<IMEIDTO> listarPorProducto(Long productoId) {
        return imeiRepository.findByProductoId(productoId).stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public List<IMEIDTO> listarEnStock() {
        return imeiRepository.findByEstado(IMEI.EstadoIMEI.EN_STOCK).stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public List<IMEIDTO> listarPorEstado(String estado) {
        IMEI.EstadoIMEI estadoEnum = IMEI.EstadoIMEI.valueOf(estado);
        return imeiRepository.findByEstado(estadoEnum).stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public IMEIDTO marcarVendido(Long id, Long clienteId) {
        IMEI imei = imeiRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("IMEI no encontrado"));
        imei.setEstado(IMEI.EstadoIMEI.VENDIDO);
        imei.setClienteId(clienteId);
        imei.setFechaVenta(java.time.LocalDateTime.now());
        imei = imeiRepository.save(imei);
        return convertirADTO(imei);
    }
    private IMEIDTO convertirADTO(IMEI imei) {
        return IMEIDTO.builder()
                .id(imei.getId())
                .numero(imei.getNumero())
                .productoId(imei.getProducto().getId())
                .estado(imei.getEstado().toString())
                .clienteId(imei.getClienteId())
                .build();
    }
}
