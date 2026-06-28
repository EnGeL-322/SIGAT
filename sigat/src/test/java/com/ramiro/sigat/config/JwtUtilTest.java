package com.ramiro.sigat.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Pruebas unitarias de RF-SEG-001 (autenticacion JWT) a nivel de la
 * utilidad que firma y valida los tokens, sin necesidad de levantar
 * el contexto de Spring.
 */
class JwtUtilTest {

    private final JwtUtil jwtUtil = new JwtUtil(
            "sigatSecurityKeyForJWTToken12345678901234567890", 86_400_000L);

    @Test
    void generaUnTokenQueContieneElRolYElEmailComoClaims() {
        String token = jwtUtil.generarToken(1L, "admin@sigat.com", "ADMIN");

        Claims claims = jwtUtil.validarYParsear(token);

        assertThat(claims.getSubject()).isEqualTo("1");
        assertThat(claims.get("email", String.class)).isEqualTo("admin@sigat.com");
        assertThat(claims.get("rol", String.class)).isEqualTo("ADMIN");
        assertThat(claims.getExpiration()).isAfter(claims.getIssuedAt());
    }

    @Test
    void rechazaUnTokenFirmadoConOtraClaveSecreta() {
        JwtUtil otroEmisor = new JwtUtil("otraClaveCompletamenteDistintaParaFirmarTokens123456", 86_400_000L);
        String tokenFalsificado = otroEmisor.generarToken(99L, "atacante@externo.com", "ADMIN");

        assertThatThrownBy(() -> jwtUtil.validarYParsear(tokenFalsificado))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void rechazaUnTokenYaExpirado() {
        JwtUtil utilConExpiracionInmediata = new JwtUtil(
                "sigatSecurityKeyForJWTToken12345678901234567890", -1000L);
        String tokenExpirado = utilConExpiracionInmediata.generarToken(1L, "admin@sigat.com", "ADMIN");

        assertThatThrownBy(() -> jwtUtil.validarYParsear(tokenExpirado))
                .isInstanceOf(JwtException.class);
    }
}
