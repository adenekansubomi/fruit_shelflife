"""
CNN Model — Fruit classification and ripeness detection.

STUB IMPLEMENTATION
───────────────────
This module provides a realistic stub that simulates what your trained CNN
will return. Replace the `StubCNNModel.predict()` body with your real
model inference once training is complete.

To swap in a real model:
  1. Train your CNN (e.g. EfficientNetB0 / MobileNetV3 / ResNet50).
  2. Save the model weights (PyTorch .pt, Keras .h5, or TFLite .tflite).
  3. Set CNN_MODEL_PATH in .env.
  4. Implement `RealCNNModel.predict()` below and update `load_cnn_model()`.

Expected output schema
──────────────────────
  fruit_class   : str              — e.g. "banana", "mango"
  ripeness_stage: str              — "unripe" | "ripe" | "overripe" | "spoiled"
  confidence    : float  [0, 1]
  visual_features:
    color_score : float  [0, 1]   — 1 = perfect color, 0 = poor
    texture_score: float [0, 1]   — 1 = smooth, 0 = wrinkled/moldy
    bruise_ratio : float [0, 1]   — fraction of surface area bruised
    mold_detected: bool
"""

import random
from typing import Optional

import numpy as np

from app.schemas import CNNOutput, RipenessStage, VisualFeatures
from app.config import settings


# ── Supported classes ─────────────────────────────────────────────────────────
# Update this list to match your CNN's output classes exactly.
FRUIT_CLASSES = [
    "apple", "avocado", "banana", "grape", "mango",
    "orange", "peach", "pineapple", "strawberry", "watermelon",
]

RIPENESS_STAGES = [s.value for s in RipenessStage]


# ── Stub model ────────────────────────────────────────────────────────────────

class StubCNNModel:
    """
    Simulates a CNN without any real weights.
    Uses image pixel statistics + optional fruit_type hint to produce
    plausible outputs for end-to-end testing before model training is done.
    """

    def predict(
        self,
        image_array: np.ndarray,
        image_stats: dict,
        fruit_type_hint: Optional[str] = None,
    ) -> CNNOutput:
        # Determine fruit class
        if fruit_type_hint:
            lower = fruit_type_hint.lower()
            fruit_class = next(
                (f for f in FRUIT_CLASSES if f in lower), "banana"
            )
        else:
            fruit_class = random.choice(FRUIT_CLASSES)

        # Derive ripeness from image brightness (greener/brighter = fresher)
        brightness = image_stats.get("brightness", 0.5)
        green_dom = image_stats.get("green_dominance", 0.0)

        ripeness_score = brightness * 0.6 + max(green_dom, 0) * 0.4
        if ripeness_score > 0.55:
            ripeness_stage = RipenessStage.ripe
        elif ripeness_score > 0.4:
            ripeness_stage = RipenessStage.overripe
        elif ripeness_score > 0.2:
            ripeness_stage = RipenessStage.spoiled
        else:
            ripeness_stage = RipenessStage.unripe

        # Add small random jitter to simulate model variance
        color_score = float(np.clip(ripeness_score + random.gauss(0, 0.05), 0, 1))
        texture_score = float(np.clip(brightness + random.gauss(0, 0.07), 0, 1))
        bruise_ratio = float(np.clip(0.3 - ripeness_score * 0.25 + random.gauss(0, 0.03), 0, 1))
        mold_detected = bruise_ratio > 0.45

        confidence = float(np.clip(0.72 + random.gauss(0, 0.08), 0.55, 0.97))

        return CNNOutput(
            fruit_class=fruit_class,
            ripeness_stage=ripeness_stage,
            confidence=confidence,
            visual_features=VisualFeatures(
                color_score=color_score,
                texture_score=texture_score,
                bruise_ratio=bruise_ratio,
                mold_detected=mold_detected,
            ),
        )


# ── Real model placeholder ────────────────────────────────────────────────────

class RealCNNModel:
    """
    Drop-in replacement for StubCNNModel once you have trained weights.

    Example (PyTorch):
        import torch
        import torchvision.models as models

        self.model = models.efficientnet_b0(weights=None)
        self.model.classifier[1] = torch.nn.Linear(1280, len(FRUIT_CLASSES) * 4)
        self.model.load_state_dict(torch.load(model_path))
        self.model.eval()

    Example (Keras/TF):
        from tensorflow import keras
        self.model = keras.models.load_model(model_path)
    """

    def __init__(self, model_path: str):
        # TODO: load your model here
        raise NotImplementedError(
            f"RealCNNModel not yet implemented. "
            f"Model path provided: {model_path}"
        )

    def predict(
        self,
        image_array: np.ndarray,
        image_stats: dict,
        fruit_type_hint: Optional[str] = None,
    ) -> CNNOutput:
        # TODO: run inference and map output to CNNOutput schema
        raise NotImplementedError


# ── Factory ───────────────────────────────────────────────────────────────────

def load_cnn_model() -> StubCNNModel | RealCNNModel:
    if settings.CNN_MODEL_PATH:
        return RealCNNModel(settings.CNN_MODEL_PATH)
    return StubCNNModel()


cnn_model = load_cnn_model()
