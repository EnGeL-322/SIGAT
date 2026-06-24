package com.ramiro.sigat.controllers;

import com.ramiro.sigat.dto.ClienteDTO;
import com.ramiro.sigat.dto.ResponseDTO;
import com.ramiro.sigat.services.*;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/clientes")
public class ClienteController {
    @Autowired
    private ClienteService clienteService;

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@Valid @RequestBody ClienteDTO dto) {
        ClienteDTO nuevo = clienteService.crearCliente(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "Cliente creado", nuevo));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        List<ClienteDTO> clientes = clienteService.listarActivos();
        return ResponseEntity.ok(new ResponseDTO(true, "Clientes obtenidos", clientes));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        ClienteDTO cliente = clienteService.obtenerPorId(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Cliente obtenido", cliente));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @Valid @RequestBody ClienteDTO dto) {
        ClienteDTO actualizado = clienteService.actualizar(id, dto);
        return ResponseEntity.ok(new ResponseDTO(true, "Cliente actualizado", actualizado));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        clienteService.eliminar(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Cliente eliminado", null));
    }
}
