"""
FreshSense API — FastAPI entry point.

Start the server:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Or via python:
    python main.py
"""

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import health, predict

app = FastAPI(
    title="FreshSense API",
    description=(
        "Fruit shelf-life prediction API. "
        "Accepts an image + optional metadata and returns a structured prediction "
        "from a CNN (visual analysis) → ML model (shelf-life regression) → "
        "LLM (natural-language explanation) pipeline."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
# Allow requests from Expo app (native + web), Flutter web, and local dev tools.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(health.router)
app.include_router(predict.router)


@app.get("/", include_in_schema=False)
async def root():
    return {
        "name": "FreshSense API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/api/v1/health",
        "predict": "/api/v1/predict",
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
