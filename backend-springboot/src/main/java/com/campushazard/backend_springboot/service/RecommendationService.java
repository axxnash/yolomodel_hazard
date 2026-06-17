package com.campushazard.backend_springboot.service;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class RecommendationService {
    private static final Map<String, String> RECOMMENDATION_BY_LABEL = Map.of(
            "broken_sink", "Inspect and repair the damaged sink. Restrict usage if leakage or sharp edges are present.",
            "broken_toilet_door", "Repair the toilet door or lock to restore privacy and safety.",
            "broken_toilet_seat", "Replace or secure the damaged toilet seat.",
            "overflowing_sink", "Clean the overflow water and report the sink issue to maintenance.",
            "overflowing_toilet", "Prevent usage immediately, clean the overflow area, and report for urgent maintenance."
    );

    public String getRecommendation(String label) {
        return RECOMMENDATION_BY_LABEL.getOrDefault(label, "Review the detected hazard and report it to maintenance.");
    }
}
