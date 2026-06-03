package com.ramiro.sigat.services;

import com.ramiro.sigat.dto.RolDTO;
import com.ramiro.sigat.models.Rol;
import com.ramiro.sigat.repositories.RolRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class RolService {
    private final RolRepository rolRepository;

    public RolService(RolRepository rolRepository) {
        this.rolRepository = rolRepository;
    }

    @Transactional
    public RolDTO crearRol(RolDTO dto) {
        String nombrePermitido = normalizarNombreRol(dto.getNombre());
        if (nombrePermitido == null) {
            throw new RuntimeException("Solo se permiten los roles ADMIN y TRABAJADOR");
        }

        Rol rol = new Rol();
        rol.setNombre(nombrePermitido);
        rol.setDescripcion(dto.getDescripcion());
        return convertirADTO(rolRepository.save(rol));
    }

    @Transactional(readOnly = true)
    public List<RolDTO> listarTodos() {
        Map<String, RolDTO> rolesPermitidos = new LinkedHashMap<>();

        rolRepository.findAll().stream()
                .map(this::convertirRolPermitido)
                .filter(rol -> rol != null)
                .forEach(rol -> rolesPermitidos.putIfAbsent(rol.getNombre(), rol));

        return rolesPermitidos.values().stream().toList();
    }

    @Transactional(readOnly = true)
    public RolDTO obtenerPorId(Long id) {
        Rol rol = rolRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rol no encontrado"));
        return convertirADTO(rol);
    }

    public boolean esRolPermitido(Rol rol) {
        return rol != null && normalizarNombreRol(rol.getNombre()) != null;
    }

    public String normalizarNombreRol(String nombre) {
        String normalizado = normalizarTexto(nombre);

        if (normalizado.contains("ADMIN")) {
            return "ADMIN";
        }

        if (normalizado.contains("TRABAJADOR") || normalizado.contains("VENDEDOR") || normalizado.contains("GERENTE")) {
            return "TRABAJADOR";
        }

        return null;
    }

    private RolDTO convertirRolPermitido(Rol rol) {
        String nombreNormalizado = normalizarNombreRol(rol.getNombre());
        if (nombreNormalizado == null) {
            return null;
        }

        return RolDTO.builder()
                .id(rol.getId())
                .nombre(nombreNormalizado)
                .descripcion(rol.getDescripcion())
                .build();
    }

    private RolDTO convertirADTO(Rol rol) {
        String nombreNormalizado = normalizarNombreRol(rol.getNombre());
        if (nombreNormalizado == null) {
            throw new RuntimeException("Rol no permitido");
        }

        return RolDTO.builder()
                .id(rol.getId())
                .nombre(nombreNormalizado)
                .descripcion(rol.getDescripcion())
                .build();
    }

    private String normalizarTexto(String texto) {
        if (texto == null) {
            return "";
        }

        return Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toUpperCase()
                .trim();
    }
}
