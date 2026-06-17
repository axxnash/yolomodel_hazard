package com.campushazard.backend_springboot.service;

import com.campushazard.backend_springboot.dto.YoloResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

@Service
public class YoloClientService {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String yoloServiceUrl;

    public YoloClientService(@Value("${yolo.service.url}") String yoloServiceUrl) {
        this.yoloServiceUrl = yoloServiceUrl;
    }

    public YoloResponse detect(MultipartFile file) {
        File tempFile = null;

        try {
            String originalFilename = file.getOriginalFilename() == null
                    ? "upload.jpg"
                    : file.getOriginalFilename();

            String suffix = getFileSuffix(originalFilename);
            tempFile = Files.createTempFile("hazard-upload-", suffix).toFile();
            file.transferTo(tempFile);

            FileSystemResource fileResource = new FileSystemResource(tempFile);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", fileResource); // Must match FastAPI parameter name

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            HttpEntity<MultiValueMap<String, Object>> requestEntity =
                    new HttpEntity<>(body, headers);

            ResponseEntity<YoloResponse> response = restTemplate.postForEntity(
                    yoloServiceUrl,
                    requestEntity,
                    YoloResponse.class
            );

            return response.getBody();

        } catch (IOException ex) {
            throw new IllegalArgumentException("Unable to process uploaded file.", ex);
        } finally {
            if (tempFile != null && tempFile.exists()) {
                tempFile.delete();
            }
        }
    }

    private String getFileSuffix(String filename) {
        int dotIndex = filename.lastIndexOf(".");
        if (dotIndex == -1) {
            return ".jpg";
        }
        return filename.substring(dotIndex);
    }
}