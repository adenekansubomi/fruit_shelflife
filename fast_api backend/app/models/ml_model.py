"""
ML Model — Shelf life regression.

STUB IMPLEMENTATION
───────────────────
Predicts remaining shelf life in days by combining:
  • CNN output  (fruit class, ripeness, visual quality)
  • Storage method
  • Outdoor temperature & humidity  (from device weather API)
  • Light exposure   (direct sunlight / shaded / dark cupboard)
  • Airflow          (open shelf / ventilated basket / closed drawer)
  • Days since purchase

To swap in a real model:
  1. Train an XGBoost / LightGBM regressor on a labelled dataset.
  2. Save: joblib.dump(model, "ml_model.pkl")
  3. Set ML_MODEL_PATH in .env.
  4. Implement RealMLModel.predict() and update load_ml_model().
"""

import random
from datetime import date
from typing import Optional

from app.schemas import CNNOutput, MLOutput, FruitStatus, ShelfLifeFactors
from app.config import settings


# ── Lookup tables ─────────────────────────────────────────────────────────────

BASELINE_DAYS: dict[str, int] = {
    "apple": 30, "avocado": 5, "banana": 7, "grape": 10,
    "mango": 14, "orange": 21, "peach": 5, "pineapple": 5,
    "strawberry": 5, "watermelon": 14, "fruit": 14,
}

RIPENESS_FACTOR: dict[str, float] = {
    "unripe": 1.4, "ripe": 1.0, "overripe": 0.45, "spoiled": 0.0,
}

STORAGE_FACTOR: dict[str, float] = {
    "room_temperature": 1.0, "refrigerator": 1.6, "freezer": 4.0,
}

# Light exposure — direct sun speeds decay; darkness slows it
LIGHT_FACTOR: dict[str, float] = {
    "direct_sunlight": 0.80,
    "shaded": 1.00,
    "dark_cupboard": 1.10,
}

# Airflow / ventilation — closed spaces retain moisture; open shelves dry out
AIRFLOW_FACTOR: dict[str, float] = {
    "open_shelf": 0.95,
    "ventilated_basket": 1.00,
    "closed_drawer": 1.10,
}


def _status_from_ratio(ratio: float) -> FruitStatus:
    if ratio > 0.7:  return FruitStatus.fresh
    if ratio > 0.4:  return FruitStatus.ripening
    if ratio > 0.05: return FruitStatus.near_expiry
    return FruitStatus.spoiled


# ── Stub model ────────────────────────────────────────────────────────────────

class StubMLModel:
    def predict(
        self,
        cnn_output: CNNOutput,
        storage_method: Optional[str],
        temperature: Optional[float],
        purchase_date: Optional[str],
        humidity: Optional[float],
        light_exposure: Optional[str],
        airflow: Optional[str],
    ) -> MLOutput:
        fruit = cnn_output.fruit_class
        base = BASELINE_DAYS.get(fruit, 14)

        # 1. Ripeness
        ripeness_mult = RIPENESS_FACTOR.get(cnn_output.ripeness_stage.value, 1.0)
        after_ripeness = base * ripeness_mult

        # 2. Storage
        storage = storage_method or "room_temperature"
        storage_mult = STORAGE_FACTOR.get(storage, 1.0)
        after_storage = after_ripeness * storage_mult

        # 3. Outdoor temperature (from weather API)
        temp_mult = 1.0
        if temperature is not None:
            if temperature > 30:   temp_mult = 0.6
            elif temperature > 25: temp_mult = 0.8
            elif temperature < 5:  temp_mult = 1.4
            elif temperature < 10: temp_mult = 1.2
        after_temp = after_storage * temp_mult

        # 4. Light exposure
        light_mult = LIGHT_FACTOR.get(light_exposure or "shaded", 1.0)
        after_light = after_temp * light_mult

        # 5. Airflow
        airflow_mult = AIRFLOW_FACTOR.get(airflow or "open_shelf", 1.0)
        after_airflow = after_light * airflow_mult

        # 6. Age since purchase
        age_reduction = 0
        if purchase_date:
            try:
                purchased = date.fromisoformat(purchase_date)
                age_reduction = (date.today() - purchased).days
            except ValueError:
                pass
        after_age = max(0.0, after_airflow - age_reduction)

        # 7. Mold / bruise penalties
        if cnn_output.visual_features.mold_detected:
            after_age = max(0.0, after_age - 2)
        bruise_penalty = cnn_output.visual_features.bruise_ratio * 3
        final = max(0.0, after_age - bruise_penalty)

        # 8. Small jitter
        final_days = max(0, int(final) + random.randint(-1, 1))

        ratio = final_days / max(base, 1)
        status = _status_from_ratio(ratio)
        confidence = max(0.5, min(0.97, 0.72 + random.gauss(0, 0.06)))

        return MLOutput(
            shelf_life_days=final_days,
            confidence=confidence,
            status=status,
            factors=ShelfLifeFactors(
                base_days=base,
                storage_adjustment=storage_mult,
                temperature_adjustment=temp_mult,
                light_adjustment=light_mult,
                airflow_adjustment=airflow_mult,
                age_reduction=age_reduction,
            ),
        )


# ── Real model placeholder ────────────────────────────────────────────────────

class RealMLModel:
    """
    Replace StubMLModel with this once training is complete.

    Feature vector order (must match training pipeline exactly):
      [ripeness_code, color_score, texture_score, bruise_ratio, mold_flag,
       storage_code, temp_normalized, light_code, airflow_code,
       humidity_normalized, days_since_purchase]
    """
    def __init__(self, model_path: str):
        raise NotImplementedError(f"RealMLModel not implemented. Path: {model_path}")

    def predict(self, *args, **kwargs) -> MLOutput:
        raise NotImplementedError


# ── Factory ───────────────────────────────────────────────────────────────────

def load_ml_model() -> StubMLModel | RealMLModel:
    if settings.ML_MODEL_PATH:
        return RealMLModel(settings.ML_MODEL_PATH)
    return StubMLModel()


ml_model = load_ml_model()
