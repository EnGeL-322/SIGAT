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
@RequestMapping("/productos")
public class ProductoController {
    @Autowired
    private ProductoService productoService;

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@Valid @RequestBody ProductoDTO dto) {
        ProductoDTO nuevo = productoService.crearProducto(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "Producto creado", nuevo));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        List<ProductoDTO> productos = productoService.listarActivos();
        return ResponseEntity.ok(new ResponseDTO(true, "Productos obtenidos", productos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        ProductoDTO producto = productoService.obtenerPorId(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Producto obtenido", producto));
    }

    @GetMapping("/bajo-stock")
    public ResponseEntity<ResponseDTO> listarBajoStock() {
        List<ProductoDTO> productos = productoService.listarBajoStock();
        return ResponseEntity.ok(new ResponseDTO(true, "Productos bajo stock", productos));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ResponseDTO> actualizar(@PathVariable Long id, @Valid @RequestBody ProductoDTO dto) {
        ProductoDTO actualizado = productoService.actualizar(id, dto);
        return ResponseEntity.ok(new ResponseDTO(true, "Producto actualizado", actualizado));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        productoService.eliminar(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Producto eliminado", null));
    }
}
