package com.ramiro.sigat.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String fromEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void enviarCodigoRecuperacion(String toEmail, String code) {
        if (fromEmail == null || fromEmail.isBlank()) {
            throw new RuntimeException("Configura spring.mail.username y spring.mail.password para enviar correos");
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(toEmail);
        message.setSubject("Codigo de recuperacion SIGAT");
        message.setText("""
                Hola,

                Tu codigo unico para restablecer la contrasena en SIGAT es: %s

                Este codigo vence en 15 minutos. Si no lo solicitaste, ignora este correo.
                """.formatted(code));

        mailSender.send(message);
    }
}
