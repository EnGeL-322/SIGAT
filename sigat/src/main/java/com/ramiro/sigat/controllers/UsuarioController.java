package com.ramiro.sigat.controllers;
import com.ramiro.sigat.dto.*;
import com.ramiro.sigat.services.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/usuarios")
@CrossOrigin(origins = "http://localhost:4200")
public class UsuarioController {
    @Autowired
    private UsuarioService usuarioService;
    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@RequestBody UsuarioDTO dto) {
        try {
            UsuarioDTO nuevo = usuarioService.crearUsuario(dto);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "Usuario creado", nuevo));
        } catch (DataIntegrityViolationException e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, "Ya existe un usuario con ese email", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        try {
            List<UsuarioDTO> usuarios = usuarioService.listarActivos();
            return ResponseEntity.ok(new ResponseDTO(true, "Usuarios obtenidos", usuarios));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            UsuarioDTO usuario = usuarioService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Usuario obtenido", usuario));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @RequestBody UsuarioDTO dto) {
        try {
            UsuarioDTO actualizado = usuarioService.actualizar(id, dto);
            return ResponseEntity.ok(new ResponseDTO(true, "Usuario actualizado", actualizado));
        } catch (DataIntegrityViolationException e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, "Ya existe un usuario con ese email", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        try {
            usuarioService.eliminar(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Usuario eliminado", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}
