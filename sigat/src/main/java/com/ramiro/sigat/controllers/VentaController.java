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
@RequestMapping("/ventas")
public class VentaController {
    @Autowired
    private VentaService ventaService;

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@Valid @RequestBody VentaRequestDTO request) {
        VentaDTO nueva = ventaService.crearVenta(request.getVenta(), request.getDetalles());
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "Venta registrada", nueva));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodas() {
        List<VentaDTO> ventas = ventaService.listarTodas();
        return ResponseEntity.ok(new ResponseDTO(true, "Ventas obtenidas", ventas));
    }

    @GetMapping("/con-detalles")
    public ResponseEntity<ResponseDTO> listarTodasConDetalles() {
        List<VentaConDetallesDTO> ventas = ventaService.listarTodasConDetalles();
        return ResponseEntity.ok(new ResponseDTO(true, "Ventas obtenidas", ventas));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        VentaDTO venta = ventaService.obtenerPorId(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Venta obtenida", venta));
    }

    @GetMapping("/{id}/detalles")
    public ResponseEntity<ResponseDTO> obtenerDetalles(@PathVariable Long id) {
        List<DetalleVentaDTO> detalles = ventaService.obtenerDetalles(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Detalles obtenidos", detalles));
    }

    @GetMapping("/cliente/{clienteId}")
    public ResponseEntity<ResponseDTO> listarPorCliente(@PathVariable Long clienteId) {
        List<VentaDTO> ventas = ventaService.listarPorCliente(clienteId);
        return ResponseEntity.ok(new ResponseDTO(true, "Ventas obtenidas", ventas));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ResponseDTO> eliminar(@PathVariable Long id) {
        ventaService.eliminar(id);
        return ResponseEntity.ok(new ResponseDTO(true, "Venta eliminada", null));
    }
}
