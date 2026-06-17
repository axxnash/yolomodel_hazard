package com.campushazard.backend_springboot.service;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class SeverityService {
    private static final Map<String, String> SEVERITY_BY_LABEL = Map.of(
            "overflowing_toilet", "High",
            "broken_toilet_door", "High",
            "overflowing_sink", "Medium",
            "broken_sink", "Medium",
            "broken_toilet_seat", "Low"
    );

    public String getSeverity(String label) {
        return SEVERITY_BY_LABEL.getOrDefault(label, "Unknown");
    }
}
