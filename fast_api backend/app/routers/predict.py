from typing import Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile, Query

from app.schemas import PredictionResponse
from app.services.pipeline import run_prediction

router = APIRouter(prefix="/api/v1", tags=["predict"])

MAX_IMAGE_BYTES = 10 * 1024 * 1024

VALID_STORAGE  = ("room_temperature", "refrigerator", "freezer")
VALID_LIGHT    = ("direct_sunlight", "shaded", "dark_cupboard")
VALID_AIRFLOW  = ("open_shelf", "ventilated_basket", "closed_drawer")


@router.post(
    "/predict",
    response_model=PredictionResponse,
    summary="Analyze a fruit image and predict shelf life",
    description=(
        "Upload a fruit photo plus optional environment metadata. "
        "The pipeline runs CNN → ML → LLM and returns a structured prediction."
    ),
)
async def predict(
    image: UploadFile = File(..., description="Fruit image (JPEG / PNG / WebP)"),
    fruit_type: Optional[str] = Form(None, description="Optional fruit name hint"),
    storage_method: Optional[str] = Form(
        None, description="room_temperature | refrigerator | freezer"),
    purchase_date: Optional[str] = Form(
        None, description="ISO purchase date YYYY-MM-DD"),
    temperature: Optional[float] = Form(
        None, description="Outdoor temperature in Celsius (from weather API)"),
    humidity: Optional[float] = Form(
        None, description="Outdoor relative humidity 0–100 (from weather API)"),
    light_exposure: Optional[str] = Form(
        None, description="direct_sunlight | shaded | dark_cupboard"),
    airflow: Optional[str] = Form(
        None, description="open_shelf | ventilated_basket | closed_drawer"),
    debug: bool = Query(False, description="Include per-model debug outputs"),
) -> PredictionResponse:

    # ── Image validation ──────────────────────────────────────────────────
    if image.content_type not in (
        "image/jpeg", "image/png", "image/webp", "image/jpg"
    ):
        raise HTTPException(
            status_code=415,
            detail="Unsupported image format. Use JPEG, PNG, or WebP.",
        )

    image_bytes = await image.read()
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image exceeds 10 MB limit.")
    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty image file.")

    # ── Metadata validation ───────────────────────────────────────────────
    if storage_method and storage_method not in VALID_STORAGE:
        raise HTTPException(
            status_code=422,
            detail=f"storage_method must be one of: {', '.join(VALID_STORAGE)}",
        )

    if light_exposure and light_exposure not in VALID_LIGHT:
        raise HTTPException(
            status_code=422,
            detail=f"light_exposure must be one of: {', '.join(VALID_LIGHT)}",
        )

    if airflow and airflow not in VALID_AIRFLOW:
        raise HTTPException(
            status_code=422,
            detail=f"airflow must be one of: {', '.join(VALID_AIRFLOW)}",
        )

    if temperature is not None and not (-50 <= temperature <= 60):
        raise HTTPException(
            status_code=422, detail="temperature must be between -50 and 60 °C.")

    if humidity is not None and not (0 <= humidity <= 100):
        raise HTTPException(
            status_code=422, detail="humidity must be between 0 and 100.")

    # ── Run pipeline ──────────────────────────────────────────────────────
    try:
        result = await run_prediction(
            image_bytes=image_bytes,
            fruit_type=fruit_type,
            storage_method=storage_method,
            purchase_date=purchase_date,
            temperature=temperature,
            humidity=humidity,
            light_exposure=light_exposure,
            airflow=airflow,
            include_debug=debug,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {e}")

    return result
