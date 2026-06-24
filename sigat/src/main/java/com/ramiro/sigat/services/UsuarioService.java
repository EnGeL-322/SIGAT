package com.ramiro.sigat.services;

import com.ramiro.sigat.exceptions.ResourceNotFoundException;

import com.ramiro.sigat.dto.UsuarioDTO;
import com.ramiro.sigat.models.Rol;
import com.ramiro.sigat.models.Usuario;
import com.ramiro.sigat.repositories.RolRepository;
import com.ramiro.sigat.repositories.UsuarioRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

@Service
public class UsuarioService {
    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;
    private final RolService rolService;

    public UsuarioService(
            UsuarioRepository usuarioRepository,
            RolRepository rolRepository,
            PasswordEncoder passwordEncoder,
            RolService rolService
    ) {
        this.usuarioRepository = usuarioRepository;
        this.rolRepository = rolRepository;
        this.passwordEncoder = passwordEncoder;
        this.rolService = rolService;
    }

    @Transactional
    public UsuarioDTO crearUsuario(UsuarioDTO dto) {
        String email = normalizarEmail(dto.getEmail());
        validarEmailDisponible(email, null);

        Usuario usuario = new Usuario();
        usuario.setEmail(email);
        usuario.setNombre(requerido(dto.getNombre(), "El nombre"));
        usuario.setApellido(requerido(dto.getApellido(), "El apellido"));
        usuario.setPassword(passwordEncoder.encode(validarPasswordNueva(dto.getPassword())));
        usuario.setActivo(true);

        if (dto.getRolId() == null) {
            throw new RuntimeException("Debe seleccionar un rol");
        }

        Rol rol = rolRepository.findById(dto.getRolId())
                .orElseThrow(() -> new ResourceNotFoundException("Rol no encontrado"));
        validarRolPermitido(rol);
        usuario.setRol(rol);

        return convertirADTO(usuarioRepository.saveAndFlush(usuario));
    }

    /**
     * Registro publico (sin sesion). Ignora cualquier rolId enviado por el
     * cliente y siempre asigna el rol de menor privilegio en el servidor.
     */
    @Transactional
    public UsuarioDTO registrarPublico(UsuarioDTO dto) {
        String email = normalizarEmail(dto.getEmail());
        validarEmailDisponible(email, null);

        Usuario usuario = new Usuario();
        usuario.setEmail(email);
        usuario.setNombre(requerido(dto.getNombre(), "El nombre"));
        usuario.setApellido(requerido(dto.getApellido(), "El apellido"));
        usuario.setPassword(passwordEncoder.encode(validarPasswordNueva(dto.getPassword())));
        usuario.setActivo(true);
        usuario.setRol(rolService.obtenerRolPorDefecto());

        return convertirADTO(usuarioRepository.saveAndFlush(usuario));
    }

    @Transactional(readOnly = true)
    public UsuarioDTO obtenerPorId(Long id) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        return convertirADTO(usuario);
    }

    @Transactional(readOnly = true)
    public UsuarioDTO obtenerPorEmail(String email) {
        Usuario usuario = usuarioRepository.findByEmailIgnoreCase(normalizarEmail(email))
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        return convertirADTO(usuario);
    }

    @Transactional(readOnly = true)
    public List<UsuarioDTO> listarTodos() {
        return usuarioRepository.findAll().stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<UsuarioDTO> listarActivos() {
        return usuarioRepository.findByActivo(true).stream()
                .map(this::convertirADTO)
                .toList();
    }

    @Transactional
    public UsuarioDTO actualizar(Long id, UsuarioDTO dto) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        String email = normalizarEmail(dto.getEmail());
        validarEmailDisponible(email, id);

        usuario.setNombre(requerido(dto.getNombre(), "El nombre"));
        usuario.setApellido(requerido(dto.getApellido(), "El apellido"));
        usuario.setEmail(email);

        if (dto.getPassword() != null && !dto.getPassword().isBlank()) {
            usuario.setPassword(passwordEncoder.encode(validarPasswordNueva(dto.getPassword())));
        }

        if (dto.getRolId() != null) {
            Rol rol = rolRepository.findById(dto.getRolId())
                    .orElseThrow(() -> new ResourceNotFoundException("Rol no encontrado"));
            validarRolPermitido(rol);
            usuario.setRol(rol);
        }

        return convertirADTO(usuarioRepository.saveAndFlush(usuario));
    }

    @Transactional
    public void eliminar(Long id) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        usuario.setActivo(false);
        usuarioRepository.save(usuario);
    }

    public boolean validarPassword(String rawPassword, String encodedPassword) {
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }

    @Transactional(readOnly = true)
    public Usuario obtenerUsuarioPorEmail(String email) {
        if (email == null || email.isBlank()) {
            return null;
        }
        return usuarioRepository.findByEmailIgnoreCase(email.trim()).orElse(null);
    }

    private UsuarioDTO convertirADTO(Usuario usuario) {
        return UsuarioDTO.builder()
                .id(usuario.getId())
                .email(usuario.getEmail())
                .nombre(usuario.getNombre())
                .apellido(usuario.getApellido())
                .rolId(usuario.getRol().getId())
                .rolNombre(rolService.normalizarNombreRol(usuario.getRol().getNombre()))
                .activo(usuario.getActivo())
                .build();
    }

    private void validarRolPermitido(Rol rol) {
        if (!rolService.esRolPermitido(rol)) {
            throw new RuntimeException("Solo se permiten los roles ADMIN y TRABAJADOR");
        }
    }

    private void validarEmailDisponible(String email, Long idPermitido) {
        usuarioRepository.findByEmailIgnoreCase(email).ifPresent(usuario -> {
            if (idPermitido == null || !usuario.getId().equals(idPermitido)) {
                throw new RuntimeException("Ya existe un usuario con ese email");
            }
        });
    }

    private String normalizarEmail(String email) {
        String valor = requerido(email, "El email").toLowerCase(Locale.ROOT);
        if (!valor.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
            throw new RuntimeException("El email no es valido");
        }
        return valor;
    }

    private String validarPasswordNueva(String password) {
        String valor = requerido(password, "La contrasena");
        if (valor.length() < 6) {
            throw new RuntimeException("La contrasena debe tener al menos 6 caracteres");
        }
        return valor;
    }

    private String requerido(String valor, String campo) {
        if (valor == null || valor.isBlank()) {
            throw new RuntimeException(campo + " es obligatorio");
        }
        return valor.trim();
    }
}
