package com.ramiro.sigat.services;
import com.ramiro.sigat.models.*;
import com.ramiro.sigat.repositories.*;
import com.ramiro.sigat.dto.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.stream.Collectors;
@Service
public class ProveedorService {
    @Autowired
    private ProveedorRepository proveedorRepository;
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
        proveedor = proveedorRepository.save(proveedor);
        return convertirADTO(proveedor);
    }
    public ProveedorDTO obtenerPorId(Long id) {
        Proveedor proveedor = proveedorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Proveedor no encontrado"));
        return convertirADTO(proveedor);
    }
    public List<ProveedorDTO> listarTodos() {
        return proveedorRepository.findAll().stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public List<ProveedorDTO> listarActivos() {
        return proveedorRepository.findByActivo(true).stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public ProveedorDTO actualizar(Long id, ProveedorDTO dto) {
        Proveedor proveedor = proveedorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Proveedor no encontrado"));
        proveedor.setNombre(dto.getNombre());
        proveedor.setEmail(dto.getEmail());
        proveedor.setTelefono(dto.getTelefono());
        proveedor.setDireccion(dto.getDireccion());
        proveedor.setContacto(dto.getContacto());
        proveedor = proveedorRepository.save(proveedor);
        return convertirADTO(proveedor);
    }
    public void eliminar(Long id) {
        Proveedor proveedor = proveedorRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Proveedor no encontrado"));
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
