package com.campushazard.backend_springboot.controller;

import com.campushazard.backend_springboot.dto.HazardResponse;
import com.campushazard.backend_springboot.service.HazardDetectionService;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class HazardDetectionController {
    private final HazardDetectionService hazardDetectionService;

    public HazardDetectionController(HazardDetectionService hazardDetectionService) {
        this.hazardDetectionService = hazardDetectionService;
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }

    @PostMapping(value = "/hazard/detect", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public HazardResponse detectHazard(@RequestPart("file") MultipartFile file) {
        return hazardDetectionService.detectHazard(file);
    }
}
