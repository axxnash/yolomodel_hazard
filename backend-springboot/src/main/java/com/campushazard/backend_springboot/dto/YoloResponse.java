package com.campushazard.backend_springboot.dto;

import java.util.ArrayList;
import java.util.List;

public class YoloResponse {
    private List<DetectionResult> detections = new ArrayList<>();

    public YoloResponse() {
    }

    public YoloResponse(List<DetectionResult> detections) {
        this.detections = detections;
    }

    public List<DetectionResult> getDetections() {
        return detections;
    }

    public void setDetections(List<DetectionResult> detections) {
        this.detections = detections;
    }
}
