package com.ramiro.sigat.exceptions;

/**
 * Se lanza cuando un recurso solicitado por id/clave no existe.
 * El GlobalExceptionHandler la traduce a HTTP 404.
 */
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
