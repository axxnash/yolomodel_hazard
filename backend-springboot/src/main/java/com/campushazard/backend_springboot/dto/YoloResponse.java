package com.campushazard.backend_springboot.dto;

import java.util.ArrayList;
import java.util.List;

public class YoloResponse {
    private String finalHazard;
    private double confidence;
    private List<DetectionResult> detections = new ArrayList<>();

    public YoloResponse() {
    }

    public YoloResponse(String finalHazard, double confidence, List<DetectionResult> detections) {
        this.finalHazard = finalHazard;
        this.confidence = confidence;
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

    public List<DetectionResult> getDetections() {
        return detections;
    }

    public void setDetections(List<DetectionResult> detections) {
        this.detections = detections;
    }
}
