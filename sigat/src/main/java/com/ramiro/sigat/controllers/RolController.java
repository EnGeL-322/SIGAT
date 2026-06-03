package com.ramiro.sigat.controllers;

import com.ramiro.sigat.dto.ResponseDTO;
import com.ramiro.sigat.dto.RolDTO;
import com.ramiro.sigat.services.RolService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/roles")
public class RolController {
    private final RolService rolService;

    public RolController(RolService rolService) {
        this.rolService = rolService;
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        try {
            List<RolDTO> roles = rolService.listarTodos();
            return ResponseEntity.ok(new ResponseDTO(true, "Roles obtenidos", roles));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            RolDTO rol = rolService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Rol obtenido", rol));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new ResponseDTO(false, e.getMessage(), null));
        }
    }

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@RequestBody RolDTO dto) {
        try {
            RolDTO nuevo = rolService.crearRol(dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "Rol creado", nuevo));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}
