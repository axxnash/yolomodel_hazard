package com.campushazard.backend_springboot.service;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class SeverityService {
    private static final Map<String, String> SEVERITY_BY_LABEL = Map.ofEntries(
            Map.entry("overflowing_toilet", "High"),
            Map.entry("broken_toilet_door", "High"),
            Map.entry("overflowing_sink", "Medium"),
            Map.entry("broken_sink", "Medium"),
            Map.entry("broken_toilet_seat", "Low"),
            Map.entry("blocked_drain", "Medium"),
            Map.entry("broken_floor_tile", "Medium"),
            Map.entry("missing_drain_cover", "High"),
            Map.entry("water_leakage", "Medium"),
            Map.entry("wet_slippery_floor", "High"),
            Map.entry("ceilingWaterStain", "Medium"),
            Map.entry("damagedSocket", "High"),
            Map.entry("exposedElectricalWire", "High"),
            Map.entry("missingCeilingTile", "Medium"),
            Map.entry("unsafeExtensionCable", "High"),
            Map.entry("broken_door_lock", "Medium"),
            Map.entry("damaged_warning_sign", "Low"),
            Map.entry("mold_damp_wall", "Medium"),
            Map.entry("obstruction_walkway", "Medium"),
            Map.entry("overflowing_trash_bin", "Medium")
    );

    public String getSeverity(String label) {
        return SEVERITY_BY_LABEL.getOrDefault(label, "Unknown");
    }
}
