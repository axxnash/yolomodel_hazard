package com.campushazard.backend_springboot.dto;

import java.util.List;

public class HazardResponse {
    private String finalHazard;
    private double confidence;
    private String severity;
    private String recommendation;
    private List<DetectionResult> detections;

    public HazardResponse() {
    }

    public HazardResponse(
            String finalHazard,
            double confidence,
            String severity,
            String recommendation,
            List<DetectionResult> detections
    ) {
        this.finalHazard = finalHazard;
        this.confidence = confidence;
        this.severity = severity;
        this.recommendation = recommendation;
        this.detections = detections;
    }

    public String getFinalHazard() {
        return finalHazard;
    }

    public void setFinalHazard(String finalHazard) {
        this.finalHazard = finalHazard;
    }

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }

    public String getSeverity() {
        return severity;
    }

    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public String getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(String recommendation) {
        this.recommendation = recommendation;
    }

    public List<DetectionResult> getDetections() {
        return detections;
    }

    public void setDetections(List<DetectionResult> detections) {
        this.detections = detections;
    }
}
