package com.ramiro.sigat.controllers;


import com.ramiro.sigat.dto.*;
import com.ramiro.sigat.models.Usuario;
import com.ramiro.sigat.services.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "http://localhost:4200")
public class AuthController {
    @Autowired
    private UsuarioService usuarioService;
    @PostMapping("/login")
    public ResponseEntity<ResponseDTO> login(@RequestBody LoginRequestDTO request) {
        try {
            Usuario usuario = usuarioService.obtenerUsuarioPorEmail(request.getEmail());
            if (usuario == null || !usuarioService.validarPassword(request.getPassword(), usuario.getPassword())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(new ResponseDTO(false, "Credenciales inválidas", null));
            }
            LoginResponseDTO response = LoginResponseDTO.builder()
                    .token("JWT_TOKEN_" + usuario.getId()) // En producción usar JWT real
                    .usuarioId(usuario.getId())
                    .nombre(usuario.getNombre())
                    .email(usuario.getEmail())
                    .rol(usuario.getRol().getNombre())
                    .build();
            return ResponseEntity.ok(new ResponseDTO(true, "Login exitoso", response));
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
}