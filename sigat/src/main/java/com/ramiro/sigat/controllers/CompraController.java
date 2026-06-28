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
@RequestMapping("/compras")
public class CompraController {
    @Autowired
    private CompraService compraService;

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@Valid @RequestBody CompraRequestDTO request) {
        CompraDTO nueva = compraService.crearCompra(request.getCompra(), request.getDetalles());
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "Compra registrada", nueva));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodas() {
        List<CompraDTO> compras = compraService.listarTodas();
        return ResponseEntity.ok(new ResponseDTO(true, "Compras obtenidas", compras));
    }

    @GetMapping("/con-detalles")
    public ResponseEntity<ResponseDTO> listarTodasConDetalles() {
        List<CompraConDetallesDTO> compras = compraService.listarTodasConDetalles();
        return ResponseEntity.ok(new ResponseDTO(true, "Compras obtenidas", compras));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        CompraDTO compra = compraService.obtenerPorId(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Compra obtenida", compra));
    }

    @GetMapping("/{id}/detalles")
    public ResponseEntity<ResponseDTO> obtenerDetalles(@PathVariable Long id) {
        List<DetalleCompraDTO> detalles = compraService.obtenerDetalles(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Detalles obtenidos", detalles));
    }

    @GetMapping("/proveedor/{proveedorId}")
    public ResponseEntity<ResponseDTO> listarPorProveedor(@PathVariable Long proveedorId) {
        List<CompraDTO> compras = compraService.listarPorProveedor(proveedorId);
        return ResponseEntity.ok(new ResponseDTO(true, "Compras obtenidas", compras));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        compraService.eliminar(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Compra eliminada", null));
    }
}
