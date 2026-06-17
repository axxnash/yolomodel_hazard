package com.campushazard.backend_springboot.service;

import com.campushazard.backend_springboot.dto.BoundingBox;
import com.campushazard.backend_springboot.dto.DetectionResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class GeminiService {
    private static final Logger LOGGER = LoggerFactory.getLogger(GeminiService.class);
    private static final int MAX_RECOMMENDATION_WORDS = 25;

    private final boolean enabled;
    private final String apiKey;
    private final String apiUrl;
    private final RestClient restClient;

    public GeminiService(
            @Value("${gemini.enabled:true}") boolean enabled,
            @Value("${gemini.api.key:}") String apiKey,
            @Value("${gemini.api.url}") String apiUrl,
            @Value("${gemini.timeout.seconds:10}") int timeoutSeconds
    ) {
        this.enabled = enabled;
        this.apiKey = apiKey;
        this.apiUrl = apiUrl;
        this.restClient = RestClient.builder()
                .requestFactory(createRequestFactory(timeoutSeconds))
                .build();
    }

    public Optional<String> generateRecommendation(DetectionResult detection, String severity) {
        if (!enabled) {
            LOGGER.info("Gemini recommendation fallback used: Gemini integration is disabled.");
            return Optional.empty();
        }

        if (apiKey == null || apiKey.isBlank()) {
            LOGGER.info("Gemini recommendation fallback used: API key is missing.");
            return Optional.empty();
        }

        try {
            @SuppressWarnings("unchecked")
            Map<String, Object> response = (Map<String, Object>) restClient.post()
                    .uri(buildUri())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(buildRequestBody(buildPrompt(detection, severity)))
                    .retrieve()
                    .body(Map.class);

            Optional<String> recommendation = extractRecommendation(response);
            if (recommendation.isEmpty()) {
                LOGGER.warn("Gemini recommendation fallback used: invalid or empty Gemini response.");
            }
            return recommendation;
        } catch (Exception ex) {
            LOGGER.warn("Gemini recommendation fallback used: Gemini request failed.", ex);
            return Optional.empty();
        }
    }

    private SimpleClientHttpRequestFactory createRequestFactory(int timeoutSeconds) {
        int safeTimeoutSeconds = Math.max(timeoutSeconds, 1);
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(safeTimeoutSeconds));
        requestFactory.setReadTimeout(Duration.ofSeconds(safeTimeoutSeconds));
        return requestFactory;
    }

    private URI buildUri() {
        return UriComponentsBuilder.fromUriString(apiUrl)
                .queryParam("key", apiKey)
                .build()
                .toUri();
    }

    private Map<String, Object> buildRequestBody(String prompt) {
        return Map.of(
                "contents", List.of(
                        Map.of(
                                "parts", List.of(
                                        Map.of("text", prompt)
                                )
                        )
                ),
                "generationConfig", Map.of(
                        "temperature", 0.2,
                        "maxOutputTokens", 80
                )
        );
    }

    private String buildPrompt(DetectionResult detection, String severity) {
        return String.format(
                Locale.US,
                "Return one short practical campus maintenance recommendation. "
                        + "Return only the recommendation, no bullets or labels. "
                        + "It must be concise, safety-oriented, actionable, and at most 25 words. "
                        + "Hazard label: %s. Confidence: %.2f. Severity: %s. Model ID: %s. Bounding box: %s.",
                detection.getLabel(),
                detection.getConfidence(),
                severity,
                detection.getModelId(),
                formatBoundingBox(detection.getBbox())
        );
    }

    private String formatBoundingBox(BoundingBox bbox) {
        if (bbox == null) {
            return "unavailable";
        }

        return String.format(
                Locale.US,
                "x1=%.1f, y1=%.1f, x2=%.1f, y2=%.1f",
                bbox.getX1(),
                bbox.getY1(),
                bbox.getX2(),
                bbox.getY2()
        );
    }

    private Optional<String> extractRecommendation(Map<String, Object> response) {
        if (response == null) {
            return Optional.empty();
        }

        Object candidatesObject = response.get("candidates");
        if (!(candidatesObject instanceof List<?> candidates) || candidates.isEmpty()) {
            return Optional.empty();
        }

        Object firstCandidateObject = candidates.get(0);
        if (!(firstCandidateObject instanceof Map<?, ?> firstCandidate)) {
            return Optional.empty();
        }

        Object contentObject = firstCandidate.get("content");
        if (!(contentObject instanceof Map<?, ?> content)) {
            return Optional.empty();
        }

        Object partsObject = content.get("parts");
        if (!(partsObject instanceof List<?> parts) || parts.isEmpty()) {
            return Optional.empty();
        }

        Object firstPartObject = parts.get(0);
        if (!(firstPartObject instanceof Map<?, ?> firstPart)) {
            return Optional.empty();
        }

        Object textObject = firstPart.get("text");
        if (!(textObject instanceof String text)) {
            return Optional.empty();
        }

        return normalizeRecommendation(text);
    }

    private Optional<String> normalizeRecommendation(String text) {
        String normalized = text
                .replaceAll("\\s+", " ")
                .replaceAll("^\"|\"$", "")
                .trim();

        if (normalized.isBlank()) {
            return Optional.empty();
        }

        return Optional.of(limitWords(normalized));
    }

    private String limitWords(String recommendation) {
        String[] words = recommendation.split("\\s+");
        if (words.length <= MAX_RECOMMENDATION_WORDS) {
            return recommendation;
        }

        String limited = String.join(" ", List.of(words).subList(0, MAX_RECOMMENDATION_WORDS));
        return limited.replaceAll("[,;:]+$", "") + ".";
    }
}
