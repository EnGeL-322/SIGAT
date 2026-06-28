package com.ramiro.sigat.security;

import com.ramiro.sigat.config.JwtUtil;
import com.ramiro.sigat.models.Rol;
import com.ramiro.sigat.models.Usuario;
import com.ramiro.sigat.repositories.RolRepository;
import com.ramiro.sigat.repositories.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RF-SEG-001 - Autenticacion y autorizacion por roles en los servicios web.
 * Verifica, contra el contexto real de Spring Security (filtros + reglas de
 * SecurityConfig), que un recurso administrativo esta protegido en tres
 * escenarios: sin token, con token de un rol insuficiente, y con token de
 * un rol autorizado.
 *
 * Usa su propia base H2 en memoria (distinta de la que usan los demas
 * @SpringBootTest) porque este test levanta un contexto web completo en un
 * puerto aleatorio: si comparte el nombre de base de datos con el contexto
 * "no-web" de las pruebas de Venta/Compra, ambos EntityManagerFactory
 * (create-drop) compiten por las mismas tablas al cerrar la JVM.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@TestPropertySource(properties = "spring.datasource.url=jdbc:h2:mem:sigat_test_security;MODE=MySQL;DB_CLOSE_DELAY=-1")
class SecurityIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private RolRepository rolRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @BeforeEach
    void configurarClienteHttpYSeedUsuarioAdmin() {
        // El HttpURLConnection del JDK no puede reintentar una autenticacion
        // fallida cuando el cuerpo del POST se envia en modo streaming; se
        // desactiva para que el test de credenciales invalidas no falle por
        // un problema del cliente HTTP en vez de la respuesta real del servidor.
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setOutputStreaming(false);
        restTemplate.getRestTemplate().setRequestFactory(factory);

        seedUsuarioAdmin();
    }

    void seedUsuarioAdmin() {
        Rol admin = rolRepository.findAll().stream()
                .filter(r -> "ADMIN".equals(r.getNombre()))
                .findFirst()
                .orElseGet(() -> rolRepository.save(Rol.builder().nombre("ADMIN").descripcion("Administrador").build()));

        if (usuarioRepository.findByEmail("admin.test@sigat.com").isEmpty()) {
            usuarioRepository.save(Usuario.builder()
                    .email("admin.test@sigat.com")
                    .nombre("Admin")
                    .apellido("Test")
                    .password(encoder.encode("Admin123!"))
                    .rol(admin)
                    .activo(true)
                    .build());
        }
    }

    private String url(String path) {
        return "http://localhost:" + port + "/api" + path;
    }

    @Test
    void sinTokenElEndpointDeUsuariosRechazaLaPeticion() {
        ResponseEntity<String> respuesta = restTemplate.getForEntity(url("/usuarios"), String.class);

        assertThat(respuesta.getStatusCode().value()).isIn(401, 403);
    }

    @Test
    void conRolTrabajadorElEndpointDeUsuariosDevuelve403() {
        String token = jwtUtil.generarToken(2L, "trabajador@sigat.com", "TRABAJADOR");
        HttpHeaders headers = new HttpHeaders();
        headers.add("Authorization", "Bearer " + token);

        ResponseEntity<String> respuesta = restTemplate.exchange(
                url("/usuarios"), org.springframework.http.HttpMethod.GET, new HttpEntity<>(headers), String.class);

        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void conRolAdminElEndpointDeUsuariosResponde200() {
        String token = jwtUtil.generarToken(1L, "admin.test@sigat.com", "ADMIN");
        HttpHeaders headers = new HttpHeaders();
        headers.add("Authorization", "Bearer " + token);

        ResponseEntity<String> respuesta = restTemplate.exchange(
                url("/usuarios"), org.springframework.http.HttpMethod.GET, new HttpEntity<>(headers), String.class);

        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    @Test
    void elLoginConCredencialesValidasDevuelveUnTokenJwt() {
        String body = "{\"email\":\"admin.test@sigat.com\",\"password\":\"Admin123!\"}";
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "application/json");

        ResponseEntity<String> respuesta = restTemplate.postForEntity(
                url("/auth/login"), new HttpEntity<>(body, headers), String.class);

        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(respuesta.getBody()).contains("token");
    }

    @Test
    void elLoginConPasswordIncorrectaEsRechazado() {
        String body = "{\"email\":\"admin.test@sigat.com\",\"password\":\"claveIncorrecta\"}";
        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "application/json");

        ResponseEntity<String> respuesta = restTemplate.postForEntity(
                url("/auth/login"), new HttpEntity<>(body, headers), String.class);

        assertThat(respuesta.getStatusCode().is4xxClientError()).isTrue();
    }
}
