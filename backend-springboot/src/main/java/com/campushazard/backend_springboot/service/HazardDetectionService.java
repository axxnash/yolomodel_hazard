package com.campushazard.backend_springboot.service;

import com.campushazard.backend_springboot.dto.DetectionResult;
import com.campushazard.backend_springboot.dto.HazardResponse;
import com.campushazard.backend_springboot.dto.YoloResponse;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Comparator;
import java.util.List;

@Service
public class HazardDetectionService {
    private final YoloClientService yoloClientService;
    private final SeverityService severityService;
    private final RecommendationService recommendationService;
    private final GeminiService geminiService;

    public HazardDetectionService(
            YoloClientService yoloClientService,
            SeverityService severityService,
            RecommendationService recommendationService,
            GeminiService geminiService
    ) {
        this.yoloClientService = yoloClientService;
        this.severityService = severityService;
        this.recommendationService = recommendationService;
        this.geminiService = geminiService;
    }

    public HazardResponse detectHazard(MultipartFile file) {
        YoloResponse yoloResponse = yoloClientService.detect(file);
        List<DetectionResult> detections = yoloResponse == null || yoloResponse.getDetections() == null
                ? List.of()
                : yoloResponse.getDetections();

        if (detections.isEmpty()) {
            return new HazardResponse("none", 0.0, "None", "No hazard detected.", detections);
        }

        DetectionResult finalDetection = detections.stream()
                .max(Comparator.comparingDouble(DetectionResult::getConfidence))
                .orElseThrow();

        String label = finalDetection.getLabel();
        String severity = severityService.getSeverity(label);
        String ruleBasedRecommendation = recommendationService.getRecommendation(label);
        String recommendation = geminiService.generateRecommendation(finalDetection, severity)
                .filter(value -> !value.isBlank())
                .orElse(ruleBasedRecommendation);

        return new HazardResponse(
                label,
                finalDetection.getConfidence(),
                severity,
                recommendation,
                detections
        );
    }
}
