package com.ramiro.sigat.controllers;
import com.ramiro.sigat.dto.*;
import com.ramiro.sigat.services.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/imei")
@CrossOrigin(origins = "http://localhost:4200")
public class IMEIController {
    @Autowired
    private IMEIService imeiService;
    @PostMapping
    public ResponseEntity<ResponseDTO> crear(@RequestBody IMEIDTO dto) {
        try {
            IMEIDTO nuevo = imeiService.crearIMEI(dto);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ResponseDTO(true, "IMEI creado", nuevo));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping
    public ResponseEntity<ResponseDTO> listarTodos() {
        try {
            List<IMEIDTO> imeis = imeiService.listarTodos();
            return ResponseEntity.ok(new ResponseDTO(true, "IMEIs obtenidos", imeis));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<ResponseDTO> obtenerPorId(@PathVariable Long id) {
        try {
            IMEIDTO imei = imeiService.obtenerPorId(id);
            return ResponseEntity.ok(new ResponseDTO(true, "IMEI obtenido", imei));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @GetMapping("/numero/{numero}")
    public ResponseEntity<ResponseDTO> obtenerPorNumero(@PathVariable String numero) {
        try {
            IMEIDTO imei = imeiService.obtenerPorNumero(numero);
            return ResponseEntity.ok(new ResponseDTO(true, "IMEI obtenido", imei));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @GetMapping("/producto/{productoId}")
    public ResponseEntity<ResponseDTO> listarPorProducto(@PathVariable Long productoId) {
        try {
            List<IMEIDTO> imeis = imeiService.listarPorProducto(productoId);
            return ResponseEntity.ok(new ResponseDTO(true, "IMEIs obtenidos", imeis));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/en-stock")
    public ResponseEntity<ResponseDTO> listarEnStock() {
        try {
            List<IMEIDTO> imeis = imeiService.listarEnStock();
            return ResponseEntity.ok(new ResponseDTO(true, "IMEIs en stock", imeis));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/vendidos")
    public ResponseEntity<ResponseDTO> listarVendidos() {
        try {
            List<IMEIDTO> imeis = imeiService.listarVendidos();
            return ResponseEntity.ok(new ResponseDTO(true, "IMEIs vendidos", imeis));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
    @GetMapping("/estado/{estado}")
    public ResponseEntity<ResponseDTO> listarPorEstado(@PathVariable String estado) {
        try {
            List<IMEIDTO> imeis = imeiService.listarPorEstado(estado);
            return ResponseEntity.ok(new ResponseDTO(true, "IMEIs por estado", imeis));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
        }
    }
}
