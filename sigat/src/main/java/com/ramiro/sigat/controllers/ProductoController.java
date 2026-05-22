package com.ramiro.sigat.controllers;
import com.ramiro.sigat.dto.*;
import com.ramiro.sigat.services.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/productos")
@CrossOrigin(origins = "http://localhost:4200")
public class ProductoController {
    @Autowired
    private ProductoService productoService;
    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@RequestBody ProductoDTO dto) {
        try {
            ProductoDTO nuevo = productoService.crearProducto(dto);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "Producto creado", nuevo));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        try {
            List<ProductoDTO> productos = productoService.listarActivos();
            return ResponseEntity.ok(new ResponseDTO(true, "Productos obtenidos", productos));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            ProductoDTO producto = productoService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Producto obtenido", producto));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @GetMapping("/bajo-stock")
    public ResponseEntity<ResponseDTO> listarBajoStock() {
        try {
            List<ProductoDTO> productos = productoService.listarBajoStock();
            return ResponseEntity.ok(new ResponseDTO(true, "Productos bajo stock", productos));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @RequestBody ProductoDTO dto) {
        try {
            ProductoDTO actualizado = productoService.actualizar(id, dto);
            return ResponseEntity.ok(new ResponseDTO(true, "Producto actualizado", actualizado));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        try {
            productoService.eliminar(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Producto eliminado", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}
