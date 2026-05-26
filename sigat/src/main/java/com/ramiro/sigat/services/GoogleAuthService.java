package com.ramiro.sigat.services;

import com.ramiro.sigat.models.Rol;
import com.ramiro.sigat.models.Usuario;
import com.ramiro.sigat.repositories.RolRepository;
import com.ramiro.sigat.repositories.UsuarioRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.Map;

@Service
public class GoogleAuthService {
    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;
    private final RolService rolService;
    private final RestTemplate restTemplate = new RestTemplate();
    private final SecureRandom random = new SecureRandom();

    @Value("${app.googleClientId:}")
    private String googleClientId;

    public GoogleAuthService(
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
    public Usuario loginConGoogle(String idToken) {
        if (googleClientId == null || googleClientId.isBlank()) {
            throw new RuntimeException("Configura app.googleClientId para iniciar sesion con Google");
        }

        Map<String, Object> payload = validarToken(idToken);
        String email = String.valueOf(payload.get("email"));
        String emailVerified = String.valueOf(payload.get("email_verified"));

        if (!"true".equalsIgnoreCase(emailVerified)) {
            throw new RuntimeException("Google no verifico este correo");
        }

        return usuarioRepository.findByEmail(email)
                .map(usuario -> {
                    if (!Boolean.TRUE.equals(usuario.getActivo())) {
                        throw new RuntimeException("Usuario inactivo");
                    }
                    return usuario;
                })
                .orElseGet(() -> crearUsuarioGoogle(payload, email));
    }

    private Map<String, Object> validarToken(String idToken) {
        String url = UriComponentsBuilder
                .fromHttpUrl("https://oauth2.googleapis.com/tokeninfo")
                .queryParam("id_token", idToken)
                .toUriString();

        Map<String, Object> payload = restTemplate.getForObject(url, Map.class);
        if (payload == null || payload.get("aud") == null) {
            throw new RuntimeException("Token de Google invalido");
        }

        if (!googleClientId.equals(String.valueOf(payload.get("aud")))) {
            throw new RuntimeException("El token de Google no pertenece a esta aplicacion");
        }

        return payload;
    }

    private Usuario crearUsuarioGoogle(Map<String, Object> payload, String email) {
        String nombre = valor(payload, "given_name", "Usuario");
        String apellido = valor(payload, "family_name", "Google");

        Usuario usuario = new Usuario();
        usuario.setEmail(email);
        usuario.setNombre(nombre);
        usuario.setApellido(apellido);
        usuario.setPassword(passwordEncoder.encode(generarPasswordAleatoria()));
        usuario.setRol(obtenerRolTrabajador());
        usuario.setActivo(true);

        return usuarioRepository.save(usuario);
    }

    private Rol obtenerRolTrabajador() {
        return rolRepository.findAll().stream()
                .filter(rol -> "TRABAJADOR".equals(rolService.normalizarNombreRol(rol.getNombre())))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Crea el rol TRABAJADOR antes de usar Google"));
    }

    private String valor(Map<String, Object> payload, String key, String fallback) {
        Object value = payload.get(key);
        return value == null || String.valueOf(value).isBlank() ? fallback : String.valueOf(value);
    }

    private String generarPasswordAleatoria() {
        byte[] bytes = new byte[24];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
