from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd


NUMERIC_COLUMNS = [
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
]

COUNT_COLUMNS = ["agreement_count"]


def jitter_probability(value: float, rng: np.random.Generator) -> float:
    if pd.isna(value):
        return 0.0
    if float(value) == 0.0:
        return 0.0
    return float(np.clip(float(value) + rng.normal(0.0, 0.04), 0.0, 1.0))


def augment_rows(df: pd.DataFrame, target_per_class: int, seed: int) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    augmented_rows: list[pd.Series] = []

    counts = df["target_label"].value_counts()
    for label, count in counts.items():
        if count >= target_per_class:
            continue

        source_rows = df[df["target_label"] == label].reset_index(drop=True)
        needed = target_per_class - count

        for index in range(needed):
            source = source_rows.iloc[int(rng.integers(0, len(source_rows)))].copy()
            source["image_id"] = f"aug_{label}_{index + 1:03d}"
            source["region_id"] = 1

            for column in NUMERIC_COLUMNS:
                source[column] = jitter_probability(source[column], rng)

            for column in COUNT_COLUMNS:
                value = int(source[column]) if not pd.isna(source[column]) else 1
                source[column] = int(np.clip(value + rng.integers(-1, 2), 1, 4))

            augmented_rows.append(source)

    if not augmented_rows:
        return df.copy()

    augmented_df = pd.DataFrame(augmented_rows)
    return pd.concat([df, augmented_df], ignore_index=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Create a synthetic balanced copy of the meta-classifier dataset.")
    parser.add_argument(
        "--input",
        default="meta_classifier_dataset.csv.xlsx",
        help="Input Excel dataset path",
    )
    parser.add_argument(
        "--output",
        default="meta_classifier_dataset_augmented.xlsx",
        help="Output Excel dataset path",
    )
    parser.add_argument(
        "--target-per-class",
        type=int,
        default=8,
        help="Minimum number of rows per target class in the augmented output",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed",
    )
    args = parser.parse_args()

    base_dir = Path(__file__).resolve().parent
    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.is_absolute():
        input_path = base_dir / input_path
    if not output_path.is_absolute():
        output_path = base_dir / output_path

    df = pd.read_excel(input_path)
    augmented = augment_rows(df, target_per_class=args.target_per_class, seed=args.seed)
    augmented.to_excel(output_path, index=False)

    print(f"Original rows: {len(df)}")
    print(f"Augmented rows: {len(augmented)}")
    print("\nClass counts after augmentation:")
    print(augmented["target_label"].value_counts().sort_index().to_string())
    print(f"\nSaved augmented dataset to: {output_path}")


if __name__ == "__main__":
    main()
