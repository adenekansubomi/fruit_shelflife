from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class FruitStatus(str, Enum):
    fresh = "fresh"
    ripening = "ripening"
    near_expiry = "near_expiry"
    spoiled = "spoiled"


# ── CNN model output ─────────────────────────────────────────────────────────

class RipenessStage(str, Enum):
    unripe = "unripe"
    ripe = "ripe"
    overripe = "overripe"
    spoiled = "spoiled"


class VisualFeatures(BaseModel):
    color_score: float = Field(..., ge=0, le=1, description="0=poor, 1=perfect color")
    texture_score: float = Field(..., ge=0, le=1, description="0=poor, 1=smooth texture")
    bruise_ratio: float = Field(..., ge=0, le=1, description="fraction of surface bruised")
    mold_detected: bool


class CNNOutput(BaseModel):
    fruit_class: str
    ripeness_stage: RipenessStage
    confidence: float = Field(..., ge=0, le=1)
    visual_features: VisualFeatures


# ── ML model output ──────────────────────────────────────────────────────────

class ShelfLifeFactors(BaseModel):
    base_days: int
    storage_adjustment: float = Field(description="multiplier from storage method")
    temperature_adjustment: float = Field(description="multiplier from outdoor temperature")
    light_adjustment: float = Field(description="multiplier from light exposure")
    airflow_adjustment: float = Field(description="multiplier from airflow/ventilation")
    age_reduction: int = Field(description="days subtracted due to purchase date")


class MLOutput(BaseModel):
    shelf_life_days: int
    confidence: float = Field(..., ge=0, le=1)
    status: FruitStatus
    factors: ShelfLifeFactors


# ── LLM output ───────────────────────────────────────────────────────────────

class LLMOutput(BaseModel):
    explanation: str
    recommendations: list[str]


# ── API request / response ───────────────────────────────────────────────────

class PredictionResponse(BaseModel):
    fruit_name: str
    shelf_life_days: int
    status: FruitStatus
    confidence: float
    explanation: str
    recommendations: list[str]
    storage_method: Optional[str] = None
    purchase_date: Optional[str] = None
    temperature: Optional[str] = None
    humidity: Optional[str] = None
    light_exposure: Optional[str] = None
    airflow: Optional[str] = None
    debug: Optional[dict] = None


class HealthResponse(BaseModel):
    status: str
    cnn_model: str
    ml_model: str
    llm_provider: str
    version: str = "1.0.0"
