package com.campushazard.backend_springboot.dto;

import com.fasterxml.jackson.annotation.JsonAlias;

public class DetectionResult {
    @JsonAlias("model_id")
    private String modelId;

    @JsonAlias("class_id")
    private int classId;

    private String label;
    private double confidence;
    private BoundingBox bbox;

    public DetectionResult() {
    }

    public DetectionResult(String modelId, int classId, String label, double confidence, BoundingBox bbox) {
        this.modelId = modelId;
        this.classId = classId;
        this.label = label;
        this.confidence = confidence;
        this.bbox = bbox;
    }

    public String getModelId() {
        return modelId;
    }

    public void setModelId(String modelId) {
        this.modelId = modelId;
    }

    public int getClassId() {
        return classId;
    }

    public void setClassId(int classId) {
        this.classId = classId;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }

    public BoundingBox getBbox() {
        return bbox;
    }

    public void setBbox(BoundingBox bbox) {
        this.bbox = bbox;
    }
}
