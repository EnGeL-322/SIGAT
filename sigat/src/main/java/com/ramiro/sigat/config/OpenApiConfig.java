package com.ramiro.sigat.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuracion de la documentacion OpenAPI / Swagger UI.
 *
 * Una vez levantado el backend, la documentacion interactiva queda disponible en:
 *   - Swagger UI:  http://<host>/api/swagger-ui.html
 *   - OpenAPI JSON: http://<host>/api/v3/api-docs
 *
 * El esquema de seguridad "bearerAuth" habilita el boton "Authorize" en Swagger UI
 * para probar los endpoints protegidos pegando el token JWT obtenido en /auth/login.
 */
@Configuration
public class OpenApiConfig {

    private static final String SCHEME_NAME = "bearerAuth";

    @Bean
    public OpenAPI sigatOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SIGAT API")
                        .description("API REST del Sistema de Gestion de Almacen Tecnologico. "
                                + "Cubre catalogo (productos, proveedores, clientes), operaciones "
                                + "(compras y ventas), inventario e IMEI, seguridad y reportes.")
                        .version("1.0.0")
                        .contact(new Contact().name("Equipo SIGAT")))
                .addSecurityItem(new SecurityRequirement().addList(SCHEME_NAME))
                .components(new Components().addSecuritySchemes(SCHEME_NAME,
                        new SecurityScheme()
                                .name(SCHEME_NAME)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Pega el token JWT obtenido en POST /auth/login")));
    }
}
