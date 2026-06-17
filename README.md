# yolomodel_hazard

## Backend and YOLO Services

Architecture:

```text
Flutter mobile app -> Spring Boot backend -> Python FastAPI YOLO service -> Spring Boot final JSON response
```

Run the Python YOLO service:

```powershell
cd yolo-service
pip install -r requirements.txt
uvicorn app:app --reload --port 8001
```

Run the Spring Boot backend:

```powershell
cd backend-springboot
$env:GEMINI_API_KEY="your_api_key"
mvn spring-boot:run
```

Gemini recommendations are optional. If the API key is missing or Gemini fails, the backend automatically returns the existing rule-based recommendation.

Postman test:

- Method: `POST`
- URL: `http://localhost:8080/api/hazard/detect`
- Body: `form-data`
- Key: `file`
- Type: `File`
