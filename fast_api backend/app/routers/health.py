from fastapi import APIRouter

from app.config import settings
from app.schemas import HealthResponse

router = APIRouter(prefix="/api/v1", tags=["health"])


@router.get("/health", response_model=HealthResponse, summary="Health check")
async def health_check() -> HealthResponse:
    cnn_status = "real" if settings.CNN_MODEL_PATH else "stub"
    ml_status = "real" if settings.ML_MODEL_PATH else "stub"
    llm_status = settings.LLM_PROVIDER

    return HealthResponse(
        status="ok",
        cnn_model=cnn_status,
        ml_model=ml_status,
        llm_provider=llm_status,
    )
