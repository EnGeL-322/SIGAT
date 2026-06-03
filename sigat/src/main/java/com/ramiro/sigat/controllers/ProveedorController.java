package com.ramiro.sigat.controllers;
import com.ramiro.sigat.dto.ProveedorDTO;
import com.ramiro.sigat.dto.ResponseDTO;
import com.ramiro.sigat.services.*;
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
    public ResponseEntity<ResponseDTO> crear(@RequestBody ProveedorDTO dto) {
        try {
            ProveedorDTO nuevo = proveedorService.crearProveedor(dto);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "Proveedor creado", nuevo));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        try {
            List<ProveedorDTO> proveedores = proveedorService.listarActivos();
            return ResponseEntity.ok(new ResponseDTO(true, "Proveedores obtenidos", proveedores));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            ProveedorDTO proveedor = proveedorService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Proveedor obtenido", proveedor));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @RequestBody ProveedorDTO dto) {
        try {
            ProveedorDTO actualizado = proveedorService.actualizar(id, dto);
            return ResponseEntity.ok(new ResponseDTO(true, "Proveedor actualizado", actualizado));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        try {
            proveedorService.eliminar(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Proveedor eliminado", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}
