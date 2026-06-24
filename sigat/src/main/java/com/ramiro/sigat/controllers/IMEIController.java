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
@RequestMapping("/imei")
public class IMEIController {
    @Autowired
    private IMEIService imeiService;

    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@Valid @RequestBody IMEIDTO dto) {
        IMEIDTO nuevo = imeiService.crearIMEI(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(new ResponseDTO(true, "IMEI creado", nuevo));
    }

    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        List<IMEIDTO> imeis = imeiService.listarTodos();
        return ResponseEntity.ok(new ResponseDTO(true, "IMEIs obtenidos", imeis));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        IMEIDTO imei = imeiService.obtenerPorId(id);
        return ResponseEntity.ok(new ResponseDTO(true, "IMEI obtenido", imei));
    }

    @GetMapping("/numero/{numero}")
    public ResponseEntity<ResponseDTO> obtenerPorNumero(@PathVariable String numero) {
        IMEIDTO imei = imeiService.obtenerPorNumero(numero);
        return ResponseEntity.ok(new ResponseDTO(true, "IMEI obtenido", imei));
    }

    @GetMapping("/producto/{productoId}")
    public ResponseEntity<ResponseDTO> listarPorProducto(@PathVariable Long productoId) {
        List<IMEIDTO> imeis = imeiService.listarPorProducto(productoId);
        return ResponseEntity.ok(new ResponseDTO(true, "IMEIs obtenidos", imeis));
    }

    @GetMapping("/en-stock")
    public ResponseEntity<ResponseDTO> listarEnStock() {
        List<IMEIDTO> imeis = imeiService.listarEnStock();
        return ResponseEntity.ok(new ResponseDTO(true, "IMEIs en stock", imeis));
    }

    @GetMapping("/vendidos")
    public ResponseEntity<ResponseDTO> listarVendidos() {
        List<IMEIDTO> imeis = imeiService.listarVendidos();
        return ResponseEntity.ok(new ResponseDTO(true, "IMEIs vendidos", imeis));
    }

    @GetMapping("/compra/{compraId}")
    public ResponseEntity<ResponseDTO> listarPorCompra(@PathVariable Long compraId) {
        List<IMEIDTO> imeis = imeiService.listarPorCompra(compraId);
        return ResponseEntity.ok(new ResponseDTO(true, "IMEIs de la compra", imeis));
    }

    @GetMapping("/estado/{estado}")
    public ResponseEntity<ResponseDTO> listarPorEstado(@PathVariable String estado) {
        List<IMEIDTO> imeis = imeiService.listarPorEstado(estado);
        return ResponseEntity.ok(new ResponseDTO(true, "IMEIs por estado", imeis));
    }
}
