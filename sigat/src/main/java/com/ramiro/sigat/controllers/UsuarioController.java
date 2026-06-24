package com.ramiro.sigat.controllers;
import com.ramiro.sigat.dto.*;
import com.ramiro.sigat.services.*;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/usuarios")
public class UsuarioController {
    @Autowired
    private UsuarioService usuarioService;

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@Valid @RequestBody UsuarioDTO dto) {
        UsuarioDTO nuevo = usuarioService.crearUsuario(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "Usuario creado", nuevo));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        List<UsuarioDTO> usuarios = usuarioService.listarActivos();
        return ResponseEntity.ok(new ResponseDTO(true, "Usuarios obtenidos", usuarios));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        UsuarioDTO usuario = usuarioService.obtenerPorId(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Usuario obtenido", usuario));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @Valid @RequestBody UsuarioDTO dto) {
        UsuarioDTO actualizado = usuarioService.actualizar(id, dto);
        return ResponseEntity.ok(new ResponseDTO(true, "Usuario actualizado", actualizado));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        usuarioService.eliminar(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Usuario eliminado", null));
    }
}
