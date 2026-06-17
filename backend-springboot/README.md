# Spring Boot Backend

Spring Boot backend for the CSC4602 Campus Hazard Detection system. It accepts image uploads from the Flutter mobile app, forwards them to the Python YOLO service, selects the highest-confidence detection as the current final hazard, and returns severity plus a recommendation.

## Run

Start the YOLO service first, then run:

```powershell
cd backend-springboot
$env:GEMINI_API_KEY="your_api_key"
mvn spring-boot:run
```

The backend runs on port `8080`.

If Gemini is unavailable, misconfigured, times out, exceeds quota, or returns an invalid response, the backend automatically uses the existing rule-based recommendation. YOLO detection success still returns HTTP 200 even when Gemini recommendation generation fails.

## Endpoints

- `GET /api/health`
- `POST /api/hazard/detect`

`POST /api/hazard/detect` accepts `multipart/form-data` with field name `file`.

## Postman Test

- Method: `POST`
- URL: `http://localhost:8080/api/hazard/detect`
- Body: `form-data`
- Key: `file`
- Type: `File`

## Configuration

`src/main/resources/application.properties`:

```properties
server.port=8080
yolo.service.url=http://localhost:8001/predict/all
spring.servlet.multipart.max-file-size=20MB
spring.servlet.multipart.max-request-size=20MB
gemini.enabled=true
gemini.api.key=${GEMINI_API_KEY:}
gemini.api.url=https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent
gemini.timeout.seconds=10
```
