package com.ramiro.sigat.services;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username:}")
    private String fromEmail;

    @Value("${spring.mail.password:}")
    private String mailPassword;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void enviarCodigoRecuperacion(String toEmail, String code) {
        boolean smtpConfigurado = fromEmail != null && !fromEmail.isBlank()
                && mailPassword != null && !mailPassword.isBlank();

        // Modo gratuito sin configuracion de correo: el codigo se muestra en los
        // logs del backend (docker logs sigat_backend) y el flujo no se rompe.
        if (!smtpConfigurado) {
            log.warn("==================================================================");
            log.warn(" SMTP no configurado - MODO GRATIS (codigo visible en consola)");
            log.warn(" Correo destino : {}", toEmail);
            log.warn(" Codigo unico   : {}", code);
            log.warn(" Vence en 5 minutos.");
            log.warn(" Para enviar correos reales define MAIL_USERNAME y MAIL_PASSWORD.");
            log.warn("==================================================================");
            return;
        }

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(toEmail);
        message.setSubject("Codigo de recuperacion SIGAT");
        message.setText("""
                Hola,

                Tu codigo unico para restablecer la contrasena en SIGAT es: %s

                Este codigo vence en 5 minutos. Si no lo solicitaste, ignora este correo.
                """.formatted(code));

        try {
            mailSender.send(message);
            log.info("Codigo de recuperacion enviado por correo a {}", toEmail);
        } catch (Exception e) {
            log.error("No se pudo enviar el correo a {}: {}", toEmail, e.getMessage());
            throw new RuntimeException("No se pudo enviar el correo. Revisa la configuracion SMTP.");
        }
    }
}
