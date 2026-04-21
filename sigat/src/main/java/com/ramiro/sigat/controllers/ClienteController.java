package com.ramiro.sigat.controllers;

import com.ramiro.sigat.dto.ClienteDTO;
import com.ramiro.sigat.dto.ResponseDTO;
import com.ramiro.sigat.services.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/clientes")
@CrossOrigin(origins = "http://localhost:4200")
public class ClienteController {
    @Autowired
    private ClienteService clienteService;
    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@RequestBody ClienteDTO dto) {
        try {
            ClienteDTO nuevo = clienteService.crearCliente(dto);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "Cliente creado", nuevo));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        try {
            List<ClienteDTO> clientes = clienteService.listarTodos();
            return ResponseEntity.ok(new ResponseDTO(true, "Clientes obtenidos", clientes));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            ClienteDTO cliente = clienteService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Cliente obtenido", cliente));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @RequestBody ClienteDTO dto) {
        try {
            ClienteDTO actualizado = clienteService.actualizar(id, dto);
            return ResponseEntity.ok(new ResponseDTO(true, "Cliente actualizado", actualizado));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        try {
            clienteService.eliminar(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Cliente eliminado", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}