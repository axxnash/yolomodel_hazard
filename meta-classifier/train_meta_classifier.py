from __future__ import annotations

import argparse
from pathlib import Path

import joblib
import pandas as pd
import numpy as np
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder, OneHotEncoder, StandardScaler


EXPECTED_COLUMNS = [
    "image_id",
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
    "target_label",
]

CATEGORICAL_COLUMNS = [
    "model1_label",
    "model2_label",
    "model3_label",
    "model4_label",
]

NUMERIC_COLUMNS = [
    "region_id",
    "model1_conf",
    "model2_conf",
    "model3_conf",
    "model4_conf",
    "iou_12",
    "iou_13",
    "iou_14",
    "iou_23",
    "iou_24",
    "iou_34",
    "agreement_count",
]


def load_dataset(dataset_path: Path) -> pd.DataFrame:
    suffix = dataset_path.suffix.lower()

    if suffix == ".csv":
        df = pd.read_csv(dataset_path)
    elif suffix in {".xlsx", ".xls"}:
        df = pd.read_excel(dataset_path)
    else:
        raise ValueError(f"Unsupported dataset format: {dataset_path.suffix}")

    missing_columns = [column for column in EXPECTED_COLUMNS if column not in df.columns]
    if missing_columns:
        raise ValueError(f"Dataset is missing required columns: {missing_columns}")

    return df


def validate_dataset(df: pd.DataFrame) -> pd.DataFrame:
    cleaned = df.copy()

    for column in CATEGORICAL_COLUMNS + ["target_label"]:
        cleaned[column] = cleaned[column].astype(str).str.strip()

    cleaned["image_id"] = cleaned["image_id"].astype(str).str.strip()

    for column in NUMERIC_COLUMNS:
        cleaned[column] = pd.to_numeric(cleaned[column], errors="coerce")

    cleaned = cleaned.dropna(subset=["target_label"])
    cleaned = cleaned[cleaned["target_label"] != ""]

    if cleaned.empty:
        raise ValueError("Dataset has no usable rows after cleaning target_label.")

    return cleaned


def build_preprocessor() -> ColumnTransformer:
    categorical_pipeline = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="constant", fill_value="none")),
            ("encoder", OneHotEncoder(handle_unknown="ignore")),
        ]
    )

    numeric_pipeline = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="constant", fill_value=0.0)),
            ("scaler", StandardScaler()),
        ]
    )

    return ColumnTransformer(
        transformers=[
            ("categorical", categorical_pipeline, CATEGORICAL_COLUMNS),
            ("numeric", numeric_pipeline, NUMERIC_COLUMNS),
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Train a toilet hazard meta-classifier from Excel/CSV.")
    parser.add_argument(
        "--dataset",
        default="meta_classifier_dataset.csv.xlsx",
        help="Path to the dataset file (.csv, .xlsx, .xls)",
    )
    parser.add_argument(
        "--output-dir",
        default="artifacts",
        help="Directory to save the trained model and preprocessors",
    )
    parser.add_argument(
        "--test-size",
        type=float,
        default=0.2,
        help="Fraction of rows used for testing",
    )
    parser.add_argument(
        "--random-state",
        type=int,
        default=42,
        help="Random seed for reproducibility",
    )
    args = parser.parse_args()

    base_dir = Path(__file__).resolve().parent
    dataset_path = Path(args.dataset)
    if not dataset_path.is_absolute():
        dataset_path = base_dir / dataset_path

    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = base_dir / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    df = validate_dataset(load_dataset(dataset_path))

    X = df[CATEGORICAL_COLUMNS + NUMERIC_COLUMNS]
    y = df["target_label"]

    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)

    preprocessor = build_preprocessor()
    X_processed = preprocessor.fit_transform(X)

    class_counts = np.bincount(y_encoded)
    can_stratify = len(set(y_encoded)) > 1 and class_counts.min() >= 2
    stratify = y_encoded if can_stratify else None

    if not can_stratify:
        print("Warning: some classes have fewer than 2 samples, so stratified split is disabled.")

    X_train, X_test, y_train, y_test = train_test_split(
        X_processed,
        y_encoded,
        test_size=args.test_size,
        random_state=args.random_state,
        stratify=stratify,
    )

    model = MLPClassifier(
        hidden_layer_sizes=(64, 32),
        activation="relu",
        solver="adam",
        alpha=1e-4,
        batch_size=8,
        learning_rate_init=0.001,
        max_iter=500,
        random_state=args.random_state,
        early_stopping=True,
        validation_fraction=0.15,
    )
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)

    target_names = label_encoder.inverse_transform(sorted(set(y_test) | set(y_pred)))
    print(f"Dataset rows: {len(df)}")
    print(f"Train rows: {len(y_train)}")
    print(f"Test rows: {len(y_test)}")
    print(f"Test accuracy: {accuracy:.4f}")
    print("\nClassification report:")
    print(
        classification_report(
            y_test,
            y_pred,
            labels=sorted(set(y_test) | set(y_pred)),
            target_names=target_names,
            zero_division=0,
        )
    )
    print("Confusion matrix:")
    print(confusion_matrix(y_test, y_pred))

    joblib.dump(model, output_dir / "meta_classifier_model.joblib")
    joblib.dump(preprocessor, output_dir / "meta_classifier_preprocessor.joblib")
    joblib.dump(label_encoder, output_dir / "meta_classifier_label_encoder.joblib")

    print(f"\nSaved model artifacts to: {output_dir}")


if __name__ == "__main__":
    main()
