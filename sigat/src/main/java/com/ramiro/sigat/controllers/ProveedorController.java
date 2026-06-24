package com.ramiro.sigat.controllers;
import com.ramiro.sigat.dto.ProveedorDTO;
import com.ramiro.sigat.dto.ResponseDTO;
import com.ramiro.sigat.services.*;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/proveedores")
public class ProveedorController {
    @Autowired
    private ProveedorService proveedorService;

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@Valid @RequestBody ProveedorDTO dto) {
        ProveedorDTO nuevo = proveedorService.crearProveedor(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "Proveedor creado", nuevo));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        List<ProveedorDTO> proveedores = proveedorService.listarActivos();
        return ResponseEntity.ok(new ResponseDTO(true, "Proveedores obtenidos", proveedores));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        ProveedorDTO proveedor = proveedorService.obtenerPorId(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Proveedor obtenido", proveedor));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @Valid @RequestBody ProveedorDTO dto) {
        ProveedorDTO actualizado = proveedorService.actualizar(id, dto);
        return ResponseEntity.ok(new ResponseDTO(true, "Proveedor actualizado", actualizado));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        proveedorService.eliminar(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Proveedor eliminado", null));
    }
}
