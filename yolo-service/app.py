from io import BytesIO
from pathlib import Path
from typing import Dict, List

from fastapi import FastAPI, File, HTTPException, UploadFile
from PIL import Image
from ultralytics import YOLO


BASE_DIR = Path(__file__).resolve().parent

MODEL_CONFIGS = {
    # Add model1/model3 here after their best.pt and class_names.txt files are ready.
    # Keep model2 unchanged unless its files move or are retrained.
    "model2": {
        "weights": BASE_DIR / "models" / "model2" / "best.pt",
        "class_names": BASE_DIR / "models" / "model2" / "class_names.txt",
    }
}

app = FastAPI(title="Campus Hazard YOLO Service")
models: Dict[str, YOLO] = {}
class_names: Dict[str, List[str]] = {}


def load_class_names(path: Path, model: YOLO) -> List[str]:
    if path.exists():
        labels = []

        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()

            if not line:
                continue

            parts = line.split(maxsplit=1)

            if len(parts) == 2 and parts[0].isdigit():
                labels.append(parts[1])
            else:
                labels.append(line)

        return labels

    names = model.names
    if isinstance(names, dict):
        return [names[index] for index in sorted(names)]
    return list(names)


@app.on_event("startup")
def startup() -> None:
    for model_id, config in MODEL_CONFIGS.items():
        weights_path = config["weights"]
        if not weights_path.exists():
            raise RuntimeError(f"Missing weights for {model_id}: {weights_path}")

        model = YOLO(str(weights_path))
        models[model_id] = model
        class_names[model_id] = load_class_names(config["class_names"], model)


@app.get("/")
def root() -> dict:
    return {
        "service": "Campus Hazard YOLO Service",
        "available_models": list(MODEL_CONFIGS.keys()),
    }


async def read_image(file: UploadFile) -> Image.Image:
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    try:
        return Image.open(BytesIO(contents)).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Uploaded file must be a valid image.") from exc


def predict_with_model(model_id: str, image: Image.Image) -> List[dict]:
    model = models[model_id]
    labels = class_names[model_id]
    results = model.predict(source=image, verbose=False)
    detections = []

    for result in results:
        for box in result.boxes:
            class_id = int(box.cls.item())
            confidence = float(box.conf.item())
            x1, y1, x2, y2 = [float(value) for value in box.xyxy[0].tolist()]
            label = labels[class_id] if class_id < len(labels) else str(class_id)

            detections.append(
                {
                    "model_id": model_id,
                    "class_id": class_id,
                    "label": label,
                    "confidence": confidence,
                    "bbox": {
                        "x1": x1,
                        "y1": y1,
                        "x2": x2,
                        "y2": y2,
                    },
                }
            )

    return detections


@app.post("/predict/model2")
async def predict_model2(file: UploadFile = File(...)) -> dict:
    image = await read_image(file)
    return {"detections": predict_with_model("model2", image)}


@app.post("/predict/all")
async def predict_all(file: UploadFile = File(...)) -> dict:
    image = await read_image(file)
    detections = []

    for model_id in MODEL_CONFIGS:
        detections.extend(predict_with_model(model_id, image))

    return {"detections": detections}


@app.post("/predict/{model_id}")
async def predict_model(model_id: str, file: UploadFile = File(...)) -> dict:
    if model_id not in MODEL_CONFIGS:
        raise HTTPException(status_code=404, detail=f"Unknown model_id: {model_id}")

    image = await read_image(file)
    return {"detections": predict_with_model(model_id, image)}
