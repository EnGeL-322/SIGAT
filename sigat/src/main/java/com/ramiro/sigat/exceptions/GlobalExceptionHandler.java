package com.ramiro.sigat.exceptions;

import com.ramiro.sigat.dto.ResponseDTO;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.stream.Collectors;

/**
 * Traduce las excepciones lanzadas por los servicios a respuestas HTTP
 * consistentes, en vez de que cada controlador repita su propio try/catch
 * y filtre mensajes internos (stack traces, SQL, nombres de columnas).
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ResponseDTO> handleNotFound(ResourceNotFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ResponseDTO(false, e.getMessage(), null));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ResponseDTO> handleValidation(MethodArgumentNotValidException e) {
        String mensaje = e.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .collect(Collectors.joining("; "));
        return ResponseEntity.badRequest().body(new ResponseDTO(false, mensaje, null));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ResponseDTO> handleDataIntegrity(DataIntegrityViolationException e) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ResponseDTO(false, "El registro ya existe o viola una restriccion de datos", null));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ResponseDTO> handleRuntime(RuntimeException e) {
        return ResponseEntity.badRequest().body(new ResponseDTO(false, e.getMessage(), null));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ResponseDTO> handleGeneric(Exception e) {
        return ResponseEntity.internalServerError()
                .body(new ResponseDTO(false, "Ocurrio un error inesperado", null));
    }
}
