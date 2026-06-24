package com.ramiro.sigat.services;

import com.ramiro.sigat.models.PasswordResetCode;
import com.ramiro.sigat.models.Usuario;
import com.ramiro.sigat.repositories.PasswordResetCodeRepository;
import com.ramiro.sigat.repositories.UsuarioRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
public class PasswordResetService {
    private static final int CODE_MIN = 100000;
    private static final int CODE_RANGE = 900000;
    private static final int EXPIRATION_MINUTES = 5;

    private final UsuarioRepository usuarioRepository;
    private final PasswordResetCodeRepository resetCodeRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final SecureRandom random = new SecureRandom();

    public PasswordResetService(
            UsuarioRepository usuarioRepository,
            PasswordResetCodeRepository resetCodeRepository,
            PasswordEncoder passwordEncoder,
            EmailService emailService
    ) {
        this.usuarioRepository = usuarioRepository;
        this.resetCodeRepository = resetCodeRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }

    /**
     * Siempre responde igual exista o no el correo, para no permitir
     * enumeracion de cuentas registradas desde el endpoint publico.
     */
    @Transactional
    public void solicitarCodigo(String email) {
        resetCodeRepository.deleteByExpiresAtBefore(LocalDateTime.now());

        usuarioRepository.findByEmail(email).ifPresent(usuario -> {
            resetCodeRepository.findByUsuarioIdAndUsadoFalse(usuario.getId()).forEach(code -> {
                code.setUsado(true);
                resetCodeRepository.save(code);
            });

            String code = generarCodigo();
            PasswordResetCode resetCode = PasswordResetCode.builder()
                    .usuario(usuario)
                    .codeHash(passwordEncoder.encode(code))
                    .expiresAt(LocalDateTime.now().plusMinutes(EXPIRATION_MINUTES))
                    .usado(false)
                    .build();

            resetCodeRepository.save(resetCode);
            emailService.enviarCodigoRecuperacion(usuario.getEmail(), code);
        });
    }

    @Transactional
    public void restablecerPassword(String email, String code, String newPassword) {
        if (newPassword == null || newPassword.length() < 6) {
            throw new RuntimeException("La nueva contrasena debe tener al menos 6 caracteres");
        }

        PasswordResetCode resetCode = resetCodeRepository
                .findTopByUsuarioEmailAndUsadoFalseOrderByFechaCreacionDesc(email)
                .orElseThrow(() -> new RuntimeException("Codigo invalido o expirado"));

        if (resetCode.getExpiresAt().isBefore(LocalDateTime.now())) {
            resetCode.setUsado(true);
            resetCodeRepository.save(resetCode);
            throw new RuntimeException("El codigo expiro, solicita uno nuevo");
        }

        if (!passwordEncoder.matches(code, resetCode.getCodeHash())) {
            throw new RuntimeException("Codigo invalido");
        }

        Usuario usuario = resetCode.getUsuario();
        usuario.setPassword(passwordEncoder.encode(newPassword));
        usuarioRepository.save(usuario);

        resetCode.setUsado(true);
        resetCodeRepository.save(resetCode);
    }

    private String generarCodigo() {
        return String.valueOf(CODE_MIN + random.nextInt(CODE_RANGE));
    }
}
