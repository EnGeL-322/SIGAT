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
@RequestMapping("/ventas")
@CrossOrigin(origins = "http://localhost:4200")
public class VentaController {
    @Autowired
    private VentaService ventaService;
    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@RequestBody Map<String, Object> payload) {
        try {
            VentaDTO ventaDTO = new VentaDTO();
            ventaDTO.setClienteId(((Number) ((Map) payload.get("venta")).get("clienteId")).longValue());
            List<Map> detallesMap = (List<Map>) payload.get("detalles");
            List<DetalleVentaDTO> detalles = detallesMap.stream()
                    .map(d -> DetalleVentaDTO.builder()
                            .productoId(((Number) d.get("productoId")).longValue())
                            .cantidad(((Number) d.getOrDefault("cantidad", 1)).intValue())
                            .imeiId(d.get("imeiId") == null ? null : ((Number) d.get("imeiId")).longValue())
                            .precioUnitario(((Number) d.get("precioUnitario")).doubleValue())
                            .build())
                    .toList();
            VentaDTO nueva = ventaService.crearVenta(ventaDTO, detalles);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "Venta registrada", nueva));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodas() {
        try {
            List<VentaDTO> ventas = ventaService.listarTodas();
            return ResponseEntity.ok(new ResponseDTO(true, "Ventas obtenidas", ventas));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            VentaDTO venta = ventaService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Venta obtenida", venta));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @GetMapping("/{id}/detalles")
    public ResponseEntity<ResponseDTO> obtenerDetalles(@PathVariable Long id) {
        try {
            List<DetalleVentaDTO> detalles = ventaService.obtenerDetalles(id);
            return ResponseEntity.ok(new ResponseDTO(true, "Detalles obtenidos", detalles));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/cliente/{clienteId}")
    public ResponseEntity<ResponseDTO> listarPorCliente(@PathVariable Long clienteId) {
        try {
            List<VentaDTO> ventas = ventaService.listarPorCliente(clienteId);
            return ResponseEntity.ok(new ResponseDTO(true, "Ventas obtenidas", ventas));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}
