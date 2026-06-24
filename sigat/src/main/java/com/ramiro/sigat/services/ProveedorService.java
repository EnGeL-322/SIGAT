package com.ramiro.sigat.services;

import com.ramiro.sigat.exceptions.ResourceNotFoundException;

import com.ramiro.sigat.dto.ProveedorDTO;
import com.ramiro.sigat.models.Proveedor;
import com.ramiro.sigat.repositories.ProveedorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ProveedorService {
    private final ProveedorRepository proveedorRepository;

    public ProveedorService(ProveedorRepository proveedorRepository) {
        this.proveedorRepository = proveedorRepository;
    }

    @Transactional
    public ProveedorDTO crearProveedor(ProveedorDTO dto) {
        if (proveedorRepository.findByRuc(dto.getRuc()).isPresent()) {
            throw new RuntimeException("Proveedor con este RUC ya existe");
        }

        Proveedor proveedor = new Proveedor();
        proveedor.setNombre(dto.getNombre());
        proveedor.setRuc(dto.getRuc());
        proveedor.setEmail(dto.getEmail());
        proveedor.setTelefono(dto.getTelefono());
        proveedor.setDireccion(dto.getDireccion());
        proveedor.setContacto(dto.getContacto());
        proveedor.setActivo(true);
        return convertirADTO(proveedorRepository.save(proveedor));
    }

    @Transactional(readOnly = true)
    public ProveedorDTO obtenerPorId(Long id) {
        Proveedor proveedor = proveedorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Proveedor no encontrado"));
        return convertirADTO(proveedor);
    }

    @Transactional(readOnly = true)
    public List<ProveedorDTO> listarTodos() {
        return proveedorRepository.findAll().stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ProveedorDTO> listarActivos() {
        return proveedorRepository.findByActivo(true).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional
    public ProveedorDTO actualizar(Long id, ProveedorDTO dto) {
        Proveedor proveedor = proveedorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Proveedor no encontrado"));
        proveedor.setNombre(dto.getNombre());
        proveedor.setEmail(dto.getEmail());
        proveedor.setTelefono(dto.getTelefono());
        proveedor.setDireccion(dto.getDireccion());
        proveedor.setContacto(dto.getContacto());
        return convertirADTO(proveedorRepository.save(proveedor));
    }

    @Transactional
    public void eliminar(Long id) {
        Proveedor proveedor = proveedorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Proveedor no encontrado"));
        proveedor.setActivo(false);
        proveedorRepository.save(proveedor);
    }

    private ProveedorDTO convertirADTO(Proveedor proveedor) {
        return ProveedorDTO.builder()
                .id(proveedor.getId())
                .nombre(proveedor.getNombre())
                .ruc(proveedor.getRuc())
                .email(proveedor.getEmail())
                .telefono(proveedor.getTelefono())
                .direccion(proveedor.getDireccion())
                .contacto(proveedor.getContacto())
                .activo(proveedor.getActivo())
                .build();
    }
}
