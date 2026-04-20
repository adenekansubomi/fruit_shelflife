"""
Prediction Pipeline — CNN → ML → LLM orchestration.
"""

import inspect
from typing import Optional

from app.models.cnn_model import cnn_model
from app.models.ml_model import ml_model
from app.services.image_processor import preprocess_image, get_image_stats
from app.services.llm_service import llm_service
from app.schemas import PredictionResponse


async def run_prediction(
    image_bytes: bytes,
    fruit_type: Optional[str] = None,
    storage_method: Optional[str] = None,
    purchase_date: Optional[str] = None,
    temperature: Optional[float] = None,
    humidity: Optional[float] = None,
    light_exposure: Optional[str] = None,
    airflow: Optional[str] = None,
    include_debug: bool = False,
) -> PredictionResponse:
    """
    Full end-to-end prediction pipeline.

    Parameters
    ----------
    image_bytes     Raw bytes of the uploaded image.
    fruit_type      Optional user-provided fruit name hint.
    storage_method  room_temperature | refrigerator | freezer
    purchase_date   ISO date string YYYY-MM-DD
    temperature     Outdoor temperature in Celsius (from device weather API)
    humidity        Outdoor relative humidity 0–100 (from device weather API)
    light_exposure  direct_sunlight | shaded | dark_cupboard
    airflow         open_shelf | ventilated_basket | closed_drawer
    include_debug   Attach per-model outputs in the response.
    """

    # ── Step 1: Preprocess image ──────────────────────────────────────────
    image_array = preprocess_image(image_bytes)
    image_stats = get_image_stats(image_bytes)

    # ── Step 2: CNN model ─────────────────────────────────────────────────
    cnn_output = cnn_model.predict(
        image_array=image_array,
        image_stats=image_stats,
        fruit_type_hint=fruit_type,
    )

    # ── Step 3: ML model ──────────────────────────────────────────────────
    ml_output = ml_model.predict(
        cnn_output=cnn_output,
        storage_method=storage_method,
        temperature=temperature,
        purchase_date=purchase_date,
        humidity=humidity,
        light_exposure=light_exposure,
        airflow=airflow,
    )

    # ── Step 4: LLM ───────────────────────────────────────────────────────
    llm_call = llm_service.generate(
        cnn_output=cnn_output,
        ml_output=ml_output,
        storage_method=storage_method,
        temperature=temperature,
        purchase_date=purchase_date,
        humidity=humidity,
        light_exposure=light_exposure,
        airflow=airflow,
    )

    if inspect.iscoroutine(llm_call):
        llm_output = await llm_call
    else:
        llm_output = llm_call

    # ── Step 5: Assemble response ─────────────────────────────────────────
    debug = None
    if include_debug:
        debug = {
            "cnn": cnn_output.model_dump(),
            "ml": ml_output.model_dump(),
        }

    return PredictionResponse(
        fruit_name=cnn_output.fruit_class.capitalize(),
        shelf_life_days=ml_output.shelf_life_days,
        status=ml_output.status,
        confidence=round((cnn_output.confidence + ml_output.confidence) / 2, 4),
        explanation=llm_output.explanation,
        recommendations=llm_output.recommendations,
        storage_method=storage_method,
        purchase_date=purchase_date,
        temperature=str(temperature) if temperature is not None else None,
        humidity=str(humidity) if humidity is not None else None,
        light_exposure=light_exposure,
        airflow=airflow,
        debug=debug,
    )
