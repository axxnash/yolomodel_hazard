from __future__ import annotations

from pathlib import Path

import joblib
import pandas as pd


BASE_DIR = Path(__file__).resolve().parent
ARTIFACTS_DIR = BASE_DIR / "artifacts"
MODEL_PATH = ARTIFACTS_DIR / "meta_classifier_model.joblib"
PREPROCESSOR_PATH = ARTIFACTS_DIR / "meta_classifier_preprocessor.joblib"
LABEL_ENCODER_PATH = ARTIFACTS_DIR / "meta_classifier_label_encoder.joblib"

COLUMNS = [
    "region_id",
    "model1_label",
    "model1_conf",
    "model2_label",
    "model2_conf",
    "model3_label",
    "model3_conf",
    "model4_label",
    "model4_conf",
    "iou_12",
    "iou_13",
    "iou_14",
    "iou_23",
    "iou_24",
    "iou_34",
    "agreement_count",
]

MODEL_IDS = ["model1", "model2", "model3", "model4"]


def _iou(box_a: dict, box_b: dict) -> float:
    inter_x1 = max(box_a["x1"], box_b["x1"])
    inter_y1 = max(box_a["y1"], box_b["y1"])
    inter_x2 = min(box_a["x2"], box_b["x2"])
    inter_y2 = min(box_a["y2"], box_b["y2"])

    inter_w = max(0.0, inter_x2 - inter_x1)
    inter_h = max(0.0, inter_y2 - inter_y1)
    intersection = inter_w * inter_h

    area_a = max(0.0, box_a["x2"] - box_a["x1"]) * max(0.0, box_a["y2"] - box_a["y1"])
    area_b = max(0.0, box_b["x2"] - box_b["x1"]) * max(0.0, box_b["y2"] - box_b["y1"])
    union = area_a + area_b - intersection

    return intersection / union if union > 0 else 0.0


class MetaClassifierPredictor:
    def __init__(self) -> None:
        self.model = joblib.load(MODEL_PATH)
        self.preprocessor = joblib.load(PREPROCESSOR_PATH)
        self.label_encoder = joblib.load(LABEL_ENCODER_PATH)

    def _select_best_detections(self, detections: list[dict]) -> dict[str, dict]:
        best_by_model: dict[str, dict] = {}

        for detection in detections:
            model_id = detection["model_id"]
            current = best_by_model.get(model_id)
            if current is None or float(detection["confidence"]) > float(current["confidence"]):
                best_by_model[model_id] = detection

        return best_by_model

    def _build_feature_row(self, detections: list[dict]) -> dict[str, object]:
        best = self._select_best_detections(detections)
        row: dict[str, object] = {"region_id": 1}

        for model_id in MODEL_IDS:
            detection = best.get(model_id)
            if detection is None:
                row[f"{model_id}_label"] = "none"
                row[f"{model_id}_conf"] = 0.0
            else:
                row[f"{model_id}_label"] = detection["label"]
                row[f"{model_id}_conf"] = float(detection["confidence"])

        pairs = [
            ("model1", "model2", "iou_12"),
            ("model1", "model3", "iou_13"),
            ("model1", "model4", "iou_14"),
            ("model2", "model3", "iou_23"),
            ("model2", "model4", "iou_24"),
            ("model3", "model4", "iou_34"),
        ]

        for left, right, column in pairs:
            if left in best and right in best:
                row[column] = _iou(best[left]["bbox"], best[right]["bbox"])
            else:
                row[column] = 0.0

        row["agreement_count"] = sum(1 for model_id in MODEL_IDS if model_id in best)
        return row

    def predict(self, detections: list[dict]) -> dict[str, object] | None:
        if not detections:
            return None

        feature_row = self._build_feature_row(detections)
        features = pd.DataFrame([[feature_row[column] for column in COLUMNS]], columns=COLUMNS)
        transformed = self.preprocessor.transform(features)

        predicted_index = self.model.predict(transformed)[0]
        predicted_label = self.label_encoder.inverse_transform([predicted_index])[0]

        if hasattr(self.model, "predict_proba"):
            probabilities = self.model.predict_proba(transformed)[0]
            confidence = float(max(probabilities))
        else:
            confidence = 0.0

        return {
            "final_hazard": predicted_label,
            "meta_confidence": confidence,
            "feature_row": feature_row,
        }
