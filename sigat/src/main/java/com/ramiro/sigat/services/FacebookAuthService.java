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
public class FacebookAuthService {
    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;
    private final RolService rolService;
    private final RestTemplate restTemplate = new RestTemplate();
    private final SecureRandom random = new SecureRandom();

    @Value("${app.facebookAppId:}")
    private String facebookAppId;

    @Value("${app.facebookAppSecret:}")
    private String facebookAppSecret;

    public FacebookAuthService(
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
    public Usuario loginConFacebook(String accessToken) {
        if (facebookAppId == null || facebookAppId.isBlank()) {
            throw new RuntimeException("Configura app.facebookAppId para iniciar sesion con Facebook");
        }
        if (accessToken == null || accessToken.isBlank()) {
            throw new RuntimeException("Facebook no devolvio un token de acceso");
        }

        verificarToken(accessToken);
        Map<String, Object> perfil = obtenerPerfil(accessToken);

        Object emailObj = perfil.get("email");
        if (emailObj == null || String.valueOf(emailObj).isBlank()) {
            throw new RuntimeException("Facebook no proporciono un correo. Registrate con tu correo.");
        }
        String email = String.valueOf(emailObj);

        return usuarioRepository.findByEmail(email)
                .map(usuario -> {
                    if (!Boolean.TRUE.equals(usuario.getActivo())) {
                        throw new RuntimeException("Usuario inactivo");
                    }
                    return usuario;
                })
                .orElseGet(() -> crearUsuarioFacebook(perfil, email));
    }

    /**
     * Verifica que el token pertenezca a esta app usando el endpoint debug_token.
     * Requiere el app secret. Si no esta configurado, se omite (el /me valida el token).
     */
    @SuppressWarnings("unchecked")
    private void verificarToken(String accessToken) {
        if (facebookAppSecret == null || facebookAppSecret.isBlank()) {
            return;
        }

        String appToken = facebookAppId + "|" + facebookAppSecret;
        String url = UriComponentsBuilder
                .fromHttpUrl("https://graph.facebook.com/debug_token")
                .queryParam("input_token", accessToken)
                .queryParam("access_token", appToken)
                .toUriString();

        Map<String, Object> respuesta = restTemplate.getForObject(url, Map.class);
        Object dataObj = respuesta == null ? null : respuesta.get("data");
        if (!(dataObj instanceof Map)) {
            throw new RuntimeException("Token de Facebook invalido");
        }

        Map<String, Object> data = (Map<String, Object>) dataObj;
        if (!Boolean.TRUE.equals(data.get("is_valid"))) {
            throw new RuntimeException("El token de Facebook es invalido o expiro");
        }
        if (!facebookAppId.equals(String.valueOf(data.get("app_id")))) {
            throw new RuntimeException("El token de Facebook no pertenece a esta aplicacion");
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> obtenerPerfil(String accessToken) {
        String url = UriComponentsBuilder
                .fromHttpUrl("https://graph.facebook.com/me")
                .queryParam("fields", "id,first_name,last_name,email")
                .queryParam("access_token", accessToken)
                .toUriString();

        Map<String, Object> perfil = restTemplate.getForObject(url, Map.class);
        if (perfil == null || perfil.get("id") == null) {
            throw new RuntimeException("No se pudo obtener el perfil de Facebook");
        }
        return perfil;
    }

    private Usuario crearUsuarioFacebook(Map<String, Object> perfil, String email) {
        Usuario usuario = new Usuario();
        usuario.setEmail(email);
        usuario.setNombre(valor(perfil, "first_name", "Usuario"));
        usuario.setApellido(valor(perfil, "last_name", "Facebook"));
        usuario.setPassword(passwordEncoder.encode(generarPasswordAleatoria()));
        usuario.setRol(obtenerRolTrabajador());
        usuario.setActivo(true);

        return usuarioRepository.save(usuario);
    }

    private Rol obtenerRolTrabajador() {
        return rolRepository.findAll().stream()
                .filter(rol -> "TRABAJADOR".equals(rolService.normalizarNombreRol(rol.getNombre())))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Crea el rol TRABAJADOR antes de usar Facebook"));
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
