package com.ramiro.sigat.services;
import com.ramiro.sigat.models.*;
import com.ramiro.sigat.repositories.*;
import com.ramiro.sigat.dto.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.stream.Collectors;
@Service
public class RolService {
    @Autowired
    private RolRepository rolRepository;
    public RolDTO crearRol(RolDTO dto) {
        Rol rol = new Rol();
        rol.setNombre(dto.getNombre());
        rol.setDescripcion(dto.getDescripcion());
        rol = rolRepository.save(rol);
        return convertirADTO(rol);
    }
    public List<RolDTO> listarTodos() {
        return rolRepository.findAll().stream()
                .map(this::convertirADTO)
                .collect(Collectors.toList());
    }
    public RolDTO obtenerPorId(Long id) {
        Rol rol = rolRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rol no encontrado"));
        return convertirADTO(rol);
    }
    private RolDTO convertirADTO(Rol rol) {
        return RolDTO.builder()
                .id(rol.getId())
                .nombre(rol.getNombre())
                .descripcion(rol.getDescripcion())
                .build();
    }
}