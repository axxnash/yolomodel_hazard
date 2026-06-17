# Teammate Guide: Model Integration, FastAPI Testing, Spring Boot Testing, and Gemini Fallback

This guide explains how teammates should add, update, and test their own YOLO model parts without depending on Alex's Model 2 work.

## Project Context

- The backend prototype is already working with Model 2.
- Model 2 uses the Python FastAPI YOLO inference service.
- Spring Boot backend calls the FastAPI service.
- Spring Boot returns final hazard, confidence, severity, recommendation, recommendation source, and detections.
- Gemini API integration is implemented with rule-based fallback.
- If Gemini API key is missing, internet is disconnected, quota is exceeded, timeout happens, or Gemini response fails, the system should still return the rule-based recommendation instead of crashing.

Current working architecture:

```txt
Flutter / Postman
-> Spring Boot Backend
-> Python FastAPI YOLO Service
-> YOLO Model Inference
-> Spring Boot severity + Gemini or fallback recommendation
-> Final JSON response
```

Current folders:

- `backend-springboot/` - Spring Boot backend
- `yolo-service/` - Python FastAPI YOLO inference service
- `yolo-service/models/model2/` - Alex's Model 2 files

Model 2 is already completed and working:

- `yolo-service/models/model2/best.pt`
- `yolo-service/models/model2/class_names.txt`

Model 2 class order:

```txt
0 broken_sink
1 broken_toilet_door
2 broken_toilet_seat
3 overflowing_sink
4 overflowing_toilet
```

## 1. How Teammates Should Add Their Own YOLO Model

Each teammate must provide:

- `best.pt`
- `class_names.txt`
- model class order
- sample prediction images or screenshots
- model evaluation result

The `class_names.txt` format must be:

```txt
0 class_name_one
1 class_name_two
2 class_name_three
3 class_name_four
4 class_name_five
```

Example folder structure:

```txt
yolo-service/
+-- models/
    +-- model1/
    |   +-- best.pt
    |   +-- class_names.txt
    +-- model2/
    |   +-- best.pt
    |   +-- class_names.txt
    +-- model3/
        +-- best.pt
        +-- class_names.txt
```

Important notes:

- Do not change Model 2 files unless necessary.
- Make sure your `class_names.txt` order matches your YOLO training `data.yaml`.
- Do not upload full datasets to GitHub.
- Dataset, raw images, and annotation evidence must be submitted through Google Drive.
- Only source code, small model files, configuration files, and documentation should be pushed to GitHub.

## 2. How to Update FastAPI YOLO Service for New Models

Open:

```txt
yolo-service/app.py
```

Find `MODEL_CONFIGS`.

Example:

```python
MODEL_CONFIGS = {
    "model1": {
        "weights": BASE_DIR / "models" / "model1" / "best.pt",
        "class_names": BASE_DIR / "models" / "model1" / "class_names.txt",
    },
    "model2": {
        "weights": BASE_DIR / "models" / "model2" / "best.pt",
        "class_names": BASE_DIR / "models" / "model2" / "class_names.txt",
    },
    "model3": {
        "weights": BASE_DIR / "models" / "model3" / "best.pt",
        "class_names": BASE_DIR / "models" / "model3" / "class_names.txt",
    }
}
```

After adding a new model:

1. Save the file.
2. Restart the FastAPI service.
3. Test `/predict/all`.

Do not remove the existing Model 2 config unless the team agrees that Model 2 files have moved or changed.

## 3. How to Run the Python FastAPI YOLO Service

Open terminal in the project root:

```bash
cd yolo-service
conda activate hazard_yolo
python -m pip install -r requirements.txt
python -m uvicorn app:app --reload --port 8001
```

Then open:

```txt
http://127.0.0.1:8001/docs
```

Test these endpoints:

```txt
GET /
POST /predict/model2
POST /predict/all
```

For POST testing:

1. Click `Try it out`.
2. Upload a test image.
3. Click `Execute`.

Expected response:

```json
{
  "detections": [
    {
      "model_id": "model2",
      "class_id": 3,
      "label": "overflowing_sink",
      "confidence": 0.86,
      "bbox": {
        "x1": 120.0,
        "y1": 80.0,
        "x2": 310.0,
        "y2": 260.0
      }
    }
  ]
}
```

If your model is added to `MODEL_CONFIGS`, you can also test its model endpoint, for example:

```txt
POST /predict/model1
POST /predict/model3
```

## 4. How to Run the Spring Boot Backend

Open another terminal:

```bash
cd backend-springboot
mvn spring-boot:run
```

Or run this class in IntelliJ:

```txt
BackendSpringbootApplication.java
```

Test health endpoint:

```txt
GET http://localhost:8080/api/health
```

Test hazard detection endpoint using Postman:

```txt
POST http://localhost:8080/api/hazard/detect
```

Postman setup:

```txt
Body -> form-data
Key: file
Type: File
Value: choose a test image
```

Expected response:

```json
{
  "finalHazard": "overflowing_sink",
  "confidence": 0.86,
  "severity": "Medium",
  "recommendation": "Clean the overflow water and report the sink issue to maintenance.",
  "recommendationSource": "GEMINI or RULE_BASED_FALLBACK",
  "detections": [
    {
      "modelId": "model2",
      "classId": 3,
      "label": "overflowing_sink",
      "confidence": 0.86,
      "bbox": {
        "x1": 120.0,
        "y1": 80.0,
        "x2": 310.0,
        "y2": 260.0
      }
    }
  ]
}
```

Important:

- The Spring Boot endpoint is `/api/hazard/detect`.
- Do not use `/api/hazard/detect/all`.
- Spring Boot internally calls FastAPI `/predict/all`.

## 5. Gemini API Setup and Fallback Behavior

Gemini API key must not be committed to GitHub.

For Windows PowerShell:

```powershell
$env:GEMINI_API_KEY="your_api_key"
```

Then run Spring Boot from the same terminal:

```bash
cd backend-springboot
mvn spring-boot:run
```

For IntelliJ:

1. Go to `Run > Edit Configurations`.
2. Select `BackendSpringbootApplication`.
3. Add environment variable:

```txt
GEMINI_API_KEY=your_api_key
```

4. Restart Spring Boot.

Fallback behavior:

- If Gemini API key is missing, the backend uses rule-based fallback.
- If internet is disconnected, the backend uses rule-based fallback.
- If Gemini quota is exceeded, the backend uses rule-based fallback.
- If Gemini timeout happens, the backend uses rule-based fallback.
- If Gemini response parsing fails, the backend uses rule-based fallback.
- `/api/hazard/detect` should still return HTTP 200 as long as YOLO inference succeeds.

Recommendation source:

- `GEMINI` means Gemini generated the recommendation.
- `RULE_BASED_FALLBACK` means fallback recommendation was used.

## 6. How to Update Rule-Based Recommendations and Severity

When a teammate adds new hazard labels in Model 1 or Model 3, they must also update the Spring Boot rule files. This is important because Gemini can fail, and the backend must still return a useful recommendation from the fallback rules.

Open:

```txt
backend-springboot/src/main/java/com/campushazard/backend_springboot/service/RecommendationService.java
```

Find `RECOMMENDATION_BY_LABEL`.

Add one recommendation for every new YOLO class label. The label must match `class_names.txt` exactly.

Example:

```java
private static final Map<String, String> RECOMMENDATION_BY_LABEL = Map.of(
        "broken_sink", "Inspect and repair the damaged sink. Restrict usage if leakage or sharp edges are present.",
        "broken_toilet_door", "Repair the toilet door or lock to restore privacy and safety.",
        "broken_toilet_seat", "Replace or secure the damaged toilet seat.",
        "overflowing_sink", "Clean the overflow water and report the sink issue to maintenance.",
        "overflowing_toilet", "Prevent usage immediately, clean the overflow area, and report for urgent maintenance.",
        "your_new_label", "Write a short, clear maintenance action for this hazard."
);
```

Recommendation writing rules:

- Keep it short and practical.
- Explain the action maintenance should take.
- Mention safety if the hazard can injure someone.
- Do not write long paragraphs.
- Do not use a different label spelling from `class_names.txt`.

Good examples:

```txt
Block access to the damaged area and report it for urgent maintenance.
Clean the spill, place a warning sign, and notify campus maintenance.
Replace the damaged fixture before allowing normal use.
```

Bad examples:

```txt
This is dangerous.
Please do something.
The model detected a problem and maybe maintenance should check it later when available.
```

Teammates should also update severity for every new label.

Open:

```txt
backend-springboot/src/main/java/com/campushazard/backend_springboot/service/SeverityService.java
```

Find `SEVERITY_BY_LABEL`.

Add each new label as `High`, `Medium`, or `Low`.

Example:

```java
private static final Map<String, String> SEVERITY_BY_LABEL = Map.of(
        "overflowing_toilet", "High",
        "broken_toilet_door", "High",
        "overflowing_sink", "Medium",
        "broken_sink", "Medium",
        "broken_toilet_seat", "Low",
        "your_new_label", "Medium"
);
```

Simple severity guide:

- `High` - urgent safety, hygiene, blockage, privacy, or access issue.
- `Medium` - needs maintenance soon but is not immediately dangerous.
- `Low` - minor damage or inconvenience.

After updating recommendation and severity rules:

1. Restart Spring Boot.
2. Run the FastAPI service.
3. Test `POST http://localhost:8080/api/hazard/detect`.
4. Confirm the response has the expected `severity` and `recommendation`.
5. Temporarily run without `GEMINI_API_KEY` to confirm fallback recommendation works.

Important:

- Gemini is optional. The rule-based recommendation must still make sense by itself.
- If a label is missing from `RecommendationService`, the backend returns a generic fallback message.
- If a label is missing from `SeverityService`, the backend returns `Unknown`.
- New labels should be added to both services before final testing.

## 7. Common Troubleshooting

### Problem: `pip is not recognized`

Use:

```bash
python -m pip install -r requirements.txt
```

### Problem: `requirements.txt not found`

Make sure your terminal is inside:

```txt
yolo-service/
```

### Problem: FastAPI returns `Field required: file`

The multipart field name must be exactly:

```txt
file
```

### Problem: Spring Boot returns `Port 8080 already in use`

Stop the old Spring Boot process, or run:

```bash
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

### Problem: Spring Boot returns 404 for `/api/hazard/detect/all`

Use:

```txt
POST http://localhost:8080/api/hazard/detect
```

Spring Boot internally calls FastAPI `/predict/all`.

### Problem: Gemini fallback says API key missing

Make sure `GEMINI_API_KEY` is set in the same terminal or IntelliJ Run Configuration.

### Problem: Gemini returns 429 Too Many Requests

Gemini quota is exceeded. This is handled by fallback. The system should still return rule-based recommendation.

### Problem: A teammate model is not loaded

Check:

- `best.pt` exists in the correct model folder.
- `class_names.txt` exists.
- `MODEL_CONFIGS` path is correct.
- FastAPI service was restarted after changing the config.

### Problem: New hazard shows `Unknown` severity

Add the label to:

```txt
backend-springboot/src/main/java/com/campushazard/backend_springboot/service/SeverityService.java
```

The label must match `class_names.txt` exactly.

### Problem: New hazard shows generic recommendation

Add the label to:

```txt
backend-springboot/src/main/java/com/campushazard/backend_springboot/service/RecommendationService.java
```

The label must match `class_names.txt` exactly.

## 8. Teammate Checklist

Before asking others to debug, each teammate should confirm:

- [ ] I placed my `best.pt` inside the correct model folder.
- [ ] I created `class_names.txt`.
- [ ] My class order matches my YOLO training `data.yaml`.
- [ ] I updated `MODEL_CONFIGS` in `yolo-service/app.py`.
- [ ] I added each new label to `SeverityService.java`.
- [ ] I added each new label to `RecommendationService.java`.
- [ ] I restarted the FastAPI service.
- [ ] I tested my model endpoint or `/predict/all`.
- [ ] I ran Spring Boot backend.
- [ ] I tested `/api/hazard/detect` using Postman.
- [ ] The response includes `finalHazard`, `confidence`, `severity`, `recommendation`, `recommendationSource`, and `detections`.
- [ ] My dataset and annotation evidence are uploaded to Google Drive, not GitHub.
