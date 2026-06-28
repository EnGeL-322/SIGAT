package com.ramiro.sigat.services;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Limita los intentos de canje del codigo de recuperacion por correo.
 * Sin esto, alguien que conoce el email de una victima puede probar los
 * ~900,000 codigos posibles via POST repetidos a /auth/reset-password
 * dentro de la ventana de 5 minutos en que el codigo es valido.
 */
@Component
public class PasswordResetAttemptLimiter {
    private static final int MAX_INTENTOS = 5;
    private static final Duration VENTANA = Duration.ofMinutes(15);

    private final Map<String, Intentos> registro = new ConcurrentHashMap<>();

    public void registrarIntento(String email) {
        String key = normalizar(email);
        Intentos actual = registro.compute(key, (k, existente) ->
                (existente == null || existente.expiro())
                        ? new Intentos()
                        : existente.incrementar()
        );

        if (actual.contador.get() > MAX_INTENTOS) {
            throw new RuntimeException("Demasiados intentos. Espera unos minutos y solicita un nuevo codigo.");
        }
    }

    public void reiniciar(String email) {
        registro.remove(normalizar(email));
    }

    private String normalizar(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    private static final class Intentos {
        private final AtomicInteger contador = new AtomicInteger(1);
        private final Instant inicio = Instant.now();

        Intentos incrementar() {
            contador.incrementAndGet();
            return this;
        }

        boolean expiro() {
            return Instant.now().isAfter(inicio.plus(VENTANA));
        }
    }
}
