package com.ramiro.sigat.util;

/**
 * Regla de longitud minima de contrasena, compartida por registro,
 * actualizacion de usuario y recuperacion de contrasena.
 */
public final class PasswordPolicy {
    public static final int MIN_LENGTH = 6;

    private PasswordPolicy() {
    }

    public static boolean cumpleLongitudMinima(String password) {
        return password != null && password.length() >= MIN_LENGTH;
    }
}
