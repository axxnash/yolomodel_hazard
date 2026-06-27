package com.campushazard.backend_springboot.service;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class RecommendationService {
    private static final Map<String, String> RECOMMENDATION_BY_LABEL = Map.ofEntries(
            Map.entry("broken_sink", "Inspect and repair the damaged sink. Restrict usage if leakage or sharp edges are present."),
            Map.entry("broken_toilet_door", "Repair the toilet door or lock to restore privacy and safety."),
            Map.entry("broken_toilet_seat", "Replace or secure the damaged toilet seat."),
            Map.entry("overflowing_sink", "Clean the overflow water and report the sink issue to maintenance."),
            Map.entry("overflowing_toilet", "Prevent usage immediately, clean the overflow area, and report for urgent maintenance."),
            Map.entry("blocked_drain", "Clear the drain blockage, remove standing water, and restore proper drainage."),
            Map.entry("broken_floor_tile", "Replace the broken floor tile and block the area until it is safe to walk on."),
            Map.entry("missing_drain_cover", "Install a replacement drain cover and restrict access until it is secured."),
            Map.entry("water_leakage", "Stop the leak source, dry the affected area, and report it for urgent repair."),
            Map.entry("wet_slippery_floor", "Dry the floor, place a warning sign, and fix the source of the slippery surface."),
            Map.entry("ceilingWaterStain", "Inspect the ceiling for leaks, repair the source, and replace damaged materials."),
            Map.entry("damagedSocket", "Switch off power to the socket and arrange immediate electrical repair."),
            Map.entry("exposedElectricalWire", "Isolate the area, cut power if possible, and repair the exposed wiring urgently."),
            Map.entry("missingCeilingTile", "Replace the missing ceiling tile and inspect the opening for hidden damage or leaks."),
            Map.entry("unsafeExtensionCable", "Remove the unsafe cable setup and replace it with a properly routed power connection."),
            Map.entry("broken_door_lock", "Repair or replace the door lock to restore safe and secure access."),
            Map.entry("damaged_warning_sign", "Replace the damaged warning sign so the hazard remains clearly marked."),
            Map.entry("mold_damp_wall", "Clean and treat the mold, then repair the moisture source behind the wall."),
            Map.entry("obstruction_walkway", "Remove the obstruction from the walkway and keep the path clear for safe access."),
            Map.entry("overflowing_trash_bin", "Empty the overflowing bin, clean the surrounding area, and increase waste collection if needed.")
    );

    public String getRecommendation(String label) {
        return RECOMMENDATION_BY_LABEL.getOrDefault(label, "Review the detected hazard and report it to maintenance.");
    }
}
