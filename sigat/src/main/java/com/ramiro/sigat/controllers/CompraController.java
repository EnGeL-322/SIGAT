package com.ramiro.sigat.controllers;
import com.ramiro.sigat.dto.*;
import com.ramiro.sigat.services.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/compras")
@CrossOrigin(origins = "http://localhost:4200")
public class CompraController {
    @Autowired
    private CompraService compraService;
    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@RequestBody Map<String, Object> payload) {
        try {
            CompraDTO compraDTO = new CompraDTO();
            compraDTO.setProveedorId(((Number) ((Map) payload.get("compra")).get("proveedorId")).longValue());
            List<Map> detallesMap = (List<Map>) payload.get("detalles");
            List<DetalleCompraDTO> detalles = detallesMap.stream()
                    .map(d -> DetalleCompraDTO.builder()
                            .productoId(((Number) d.get("productoId")).longValue())
                            .cantidad(((Number) d.get("cantidad")).intValue())
                            .precioUnitario(((Number) d.get("precioUnitario")).doubleValue())
                            .build())
                    .toList();
            CompraDTO nueva = compraService.crearCompra(compraDTO, detalles);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "Compra registrada", nueva));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodas() {
        try {
            List<CompraDTO> compras = compraService.listarTodas();
            return ResponseEntity.ok(new ResponseDTO(true, "Compras obtenidas", compras));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            CompraDTO compra = compraService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Compra obtenida", compra));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @GetMapping("/proveedor/{proveedorId}")
    public ResponseEntity<ResponseDTO> listarPorProveedor(@PathVariable Long proveedorId) {
        try {
            List<CompraDTO> compras = compraService.listarPorProveedor(proveedorId);
            return ResponseEntity.ok(new ResponseDTO(true, "Compras obtenidas", compras));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}
