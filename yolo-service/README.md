# YOLO Service

FastAPI service for campus hazard object detection. The current service loads Model 2 for toilet and sink hazards from `models/model2/best.pt`.

## Run

```powershell
cd yolo-service
pip install -r requirements.txt
uvicorn app:app --reload --port 8001
```

## Endpoints

- `GET /` returns service status and available models.
- `POST /predict/model2` runs Model 2 only.
- `POST /predict/all` currently runs Model 2 and is structured so Model 1 and Model 3 can be added later.

Upload images as `multipart/form-data` with field name `file`.

Example response:

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
