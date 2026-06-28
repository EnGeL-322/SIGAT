package com.ramiro.sigat.controllers;

import com.ramiro.sigat.dto.DashboardStatsDTO;
import com.ramiro.sigat.dto.ResponseDTO;
import com.ramiro.sigat.services.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/dashboard")
public class DashboardController {
    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/stats")
    public ResponseEntity<ResponseDTO> stats() {
        DashboardStatsDTO stats = dashboardService.obtenerEstadisticas();
        return ResponseEntity.ok(new ResponseDTO(true, "Estadisticas obtenidas", stats));
    }
}
