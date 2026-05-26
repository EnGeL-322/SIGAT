package com.ramiro.sigat.controllers;

import com.ramiro.sigat.dto.*;
import com.ramiro.sigat.models.Usuario;
import com.ramiro.sigat.services.GoogleAuthService;
import com.ramiro.sigat.services.PasswordResetService;
import com.ramiro.sigat.services.RolService;
import com.ramiro.sigat.services.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "http://localhost:4200")
public class AuthController {
    @Autowired
    private UsuarioService usuarioService;
    @Autowired
    private RolService rolService;
    @Autowired
    private GoogleAuthService googleAuthService;
    @Autowired
    private PasswordResetService passwordResetService;

    @Value("${app.googleClientId:}")
    private String googleClientId;

    @PostMapping("/login")
    public ResponseEntity<ResponseDTO> login(@RequestBody LoginRequestDTO request) {
        try {
            Usuario usuario = usuarioService.obtenerUsuarioPorEmail(request.getEmail());
            if (usuario == null || !usuarioService.validarPassword(request.getPassword(), usuario.getPassword())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new ResponseDTO(false, "Credenciales invalidas", null));
            }

            return ResponseEntity.ok(new ResponseDTO(true, "Login exitoso", crearLoginResponse(usuario)));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ResponseDTO(false, "Error en login: " + e.getMessage(), null));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<ResponseDTO> register(@RequestBody UsuarioDTO usuarioDTO) {
        try {
            UsuarioDTO nuevo = usuarioService.crearUsuario(usuarioDTO);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "Usuario registrado exitosamente", nuevo));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ResponseDTO(false, "Error al registrar: " + e.getMessage(), null));
        }
    }

    @GetMapping("/config")
    public ResponseEntity<ResponseDTO> config() {
        AuthConfigDTO config = AuthConfigDTO.builder()
                .googleClientId(googleClientId)
                .build();
        return ResponseEntity.ok(new ResponseDTO(true, "Configuracion obtenida", config));
    }

    @PostMapping("/google")
    public ResponseEntity<ResponseDTO> google(@RequestBody GoogleLoginRequestDTO request) {
        try {
            Usuario usuario = googleAuthService.loginConGoogle(request.getIdToken());
            return ResponseEntity.ok(new ResponseDTO(true, "Login con Google exitoso", crearLoginResponse(usuario)));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ResponseDTO(false, "Error con Google: " + e.getMessage(), null));
        }
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ResponseDTO> forgotPassword(@RequestBody ForgotPasswordRequestDTO request) {
        try {
            passwordResetService.solicitarCodigo(request.getEmail());
            return ResponseEntity.ok(new ResponseDTO(true, "Codigo enviado al correo", null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ResponseDTO(false, "Error al enviar codigo: " + e.getMessage(), null));
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<ResponseDTO> resetPassword(@RequestBody ResetPasswordRequestDTO request) {
        try {
            passwordResetService.restablecerPassword(request.getEmail(), request.getCode(), request.getNewPassword());
            return ResponseEntity.ok(new ResponseDTO(true, "Contrasena actualizada", null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ResponseDTO(false, "Error al actualizar contrasena: " + e.getMessage(), null));
        }
    }

    private LoginResponseDTO crearLoginResponse(Usuario usuario) {
        return LoginResponseDTO.builder()
                .token("JWT_TOKEN_" + usuario.getId())
                .usuarioId(usuario.getId())
                .nombre(usuario.getNombre())
                .email(usuario.getEmail())
                .rol(rolService.normalizarNombreRol(usuario.getRol().getNombre()))
                .build();
    }
}
