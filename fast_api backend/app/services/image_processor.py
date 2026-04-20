"""
Image preprocessing utilities.

Reads an uploaded image and returns a normalized numpy array ready for
the CNN model. When you integrate a real CNN, only this file needs
updating — everything else in the pipeline stays the same.
"""

import io
from typing import Optional

import numpy as np
from PIL import Image


# Target size for CNN input (change to match your model's input layer)
CNN_INPUT_SIZE = (224, 224)

# ImageNet-style normalization (update if your model uses different stats)
IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def preprocess_image(image_bytes: bytes) -> np.ndarray:
    """
    Load raw image bytes, resize, and normalize to a float32 array.

    Returns shape: (1, H, W, 3)  — batch dimension included for model.predict().
    """
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize(CNN_INPUT_SIZE, Image.LANCZOS)
    arr = np.array(image, dtype=np.float32) / 255.0
    arr = (arr - IMAGENET_MEAN) / IMAGENET_STD
    return np.expand_dims(arr, axis=0)


def get_image_stats(image_bytes: bytes) -> dict:
    """
    Compute simple visual statistics used as a fallback when no CNN is loaded.
    Returns average RGB channel values and a rough brightness score.
    """
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image_small = image.resize((64, 64), Image.LANCZOS)
    arr = np.array(image_small, dtype=np.float32) / 255.0

    r_mean, g_mean, b_mean = arr[:, :, 0].mean(), arr[:, :, 1].mean(), arr[:, :, 2].mean()
    brightness = (r_mean + g_mean + b_mean) / 3

    # Crude heuristic: greener images tend to be fresher
    green_dominance = g_mean - (r_mean + b_mean) / 2

    return {
        "r_mean": float(r_mean),
        "g_mean": float(g_mean),
        "b_mean": float(b_mean),
        "brightness": float(brightness),
        "green_dominance": float(green_dominance),
    }
