"""
LLM Service — Natural language explanation and recommendations.

STUB IMPLEMENTATION
───────────────────
Rule-based templates that produce human-readable explanations covering:
  • Visual quality (from CNN)
  • Shelf life estimate (from ML model)
  • Storage method, light exposure, airflow, outdoor weather

To swap in a real LLM:
  Set LLM_PROVIDER=openai or LLM_PROVIDER=anthropic in .env.
"""

import json
import random
from typing import Optional

from app.schemas import CNNOutput, MLOutput, LLMOutput, FruitStatus
from app.config import settings


# ── Status-level explanation templates ───────────────────────────────────────

_EXPLANATIONS: dict[str, dict[str, str]] = {
    "fresh": {
        "ripe":    "Visual analysis confirms this {fruit} is in excellent condition with vibrant color and firm texture.",
        "unripe":  "This {fruit} is still developing — it appears unripe with firm texture and underdeveloped color.",
        "default": "This {fruit} appears fresh with good color and no visible deterioration.",
    },
    "ripening": {
        "overripe": "This {fruit} is past peak ripeness, with noticeable softening and color changes.",
        "default":  "This {fruit} shows signs of active ripening — ideal for consumption within the next few days.",
    },
    "near_expiry": {
        "overripe": "The {fruit} shows significant deterioration. Quality has declined considerably.",
        "default":  "This {fruit} is near the end of its optimal window with visible softening and color change.",
    },
    "spoiled": {
        "spoiled": "Spoilage indicators detected — mold, off-color, or advanced decay visible. Do not consume.",
        "default": "This {fruit} has passed its consumption window. Discard immediately.",
    },
}

_RECOMMENDATIONS: dict[str, list[str]] = {
    "fresh":       ["Store at optimal temperature to maintain freshness.",
                    "Keep away from ethylene-producing fruits like bananas.",
                    "Check daily for any signs of bruising or mold."],
    "ripening":    ["Consume within the next few days for best quality.",
                    "Move to the refrigerator to slow the ripening process.",
                    "Ideal time to use in smoothies, jams, or baked goods."],
    "near_expiry": ["Consume today or tomorrow to avoid waste.",
                    "Consider freezing if you cannot eat immediately.",
                    "Inspect carefully before eating — remove bruised spots."],
    "spoiled":     ["Discard immediately — do not consume.",
                    "Clean the storage area to prevent mold spread.",
                    "Check nearby fruits for signs of contamination."],
}

_FRUIT_TIPS: dict[str, dict[str, str]] = {
    "banana":     {"fresh": "Keep at room temperature — refrigerating bananas blackens the skin.",
                   "ripening": "Place in a paper bag to concentrate ethylene and speed ripening.",
                   "near_expiry": "Freeze peeled bananas for smoothies or banana bread."},
    "mango":      {"fresh": "Store at room temperature away from direct sunlight.",
                   "ripening": "Place in a paper bag with an apple to accelerate ripening.",
                   "near_expiry": "Dice and freeze in an airtight bag for up to 6 months."},
    "apple":      {"fresh": "Apples last longest in the refrigerator crisper drawer.",
                   "near_expiry": "Use in applesauce, pies, or crisps before full spoilage."},
    "strawberry": {"fresh": "Do not wash until ready to eat — moisture accelerates decay.",
                   "ripening": "Refrigerate and consume within 1–2 days.",
                   "near_expiry": "Blend into sauce or jam before they deteriorate further."},
    "avocado":    {"fresh": "Leave at room temperature to finish ripening.",
                   "ripening": "Once cut, brush with lemon juice and refrigerate."},
}

_STORAGE_NOTES: dict[str, str] = {
    "refrigerator":     "Refrigeration has been factored into this estimate, extending shelf life.",
    "freezer":          "Freezer storage significantly extends longevity.",
    "room_temperature": "",
}

_LIGHT_NOTES: dict[str, str] = {
    "direct_sunlight": "Direct sunlight is accelerating deterioration — move to a shaded spot.",
    "shaded":          "",
    "dark_cupboard":   "Dark storage conditions are helping slow the ripening process.",
}

_AIRFLOW_NOTES: dict[str, str] = {
    "open_shelf":        "Open-shelf storage increases moisture loss over time.",
    "ventilated_basket": "A ventilated basket provides good airflow while protecting the fruit.",
    "closed_drawer":     "The enclosed drawer retains moisture, slowing moisture loss.",
}

_LIGHT_RECS: dict[str, str] = {
    "direct_sunlight": "Move the fruit away from direct sunlight to slow UV and heat-driven decay.",
    "dark_cupboard":   "",
    "shaded":          "",
}

_AIRFLOW_RECS: dict[str, str] = {
    "closed_drawer":    "Ensure occasional ventilation to prevent condensation and mold.",
    "open_shelf":       "Consider a ventilated basket to balance air circulation and moisture retention.",
    "ventilated_basket": "",
}

_TEMP_NOTES: list[tuple[tuple[float, float], str]] = [
    ((30, 100), "The high outdoor temperature ({t}°C) may accelerate ripening even indoors."),
    ((25, 30),  "Warm outdoor conditions ({t}°C) have been factored into this estimate."),
    ((0, 10),   "Cool outdoor conditions ({t}°C) are beneficial for shelf life."),
    ((-50, 0),  "Near-freezing outdoor temperatures ({t}°C) are significantly slowing ripening."),
]


class StubLLM:
    def generate(
        self,
        cnn_output: CNNOutput,
        ml_output: MLOutput,
        storage_method: Optional[str],
        temperature: Optional[float],
        purchase_date: Optional[str],
        humidity: Optional[float],
        light_exposure: Optional[str],
        airflow: Optional[str],
    ) -> LLMOutput:
        fruit  = cnn_output.fruit_class
        status = ml_output.status.value
        ripeness = cnn_output.ripeness_stage.value
        days = ml_output.shelf_life_days

        # 1. Base explanation
        exp_map = _EXPLANATIONS.get(status, _EXPLANATIONS["fresh"])
        template = exp_map.get(ripeness, exp_map["default"])
        explanation = template.format(fruit=fruit)

        # 2. Shelf life clause
        if days > 1:
            explanation += f" Based on all environmental factors, approximately {days} days of shelf life remain."
        elif days == 1:
            explanation += " Consume today for best quality."
        else:
            explanation += " This fruit has passed its optimal consumption window."

        # 3. Storage note
        storage_note = _STORAGE_NOTES.get(storage_method or "room_temperature", "")
        if storage_note:
            explanation += f" {storage_note}"

        # 4. Light note
        light_note = _LIGHT_NOTES.get(light_exposure or "shaded", "")
        if light_note:
            explanation += f" {light_note}"

        # 5. Airflow note
        airflow_note = _AIRFLOW_NOTES.get(airflow or "open_shelf", "")
        if airflow_note:
            explanation += f" {airflow_note}"

        # 6. Temperature note
        if temperature is not None:
            for (lo, hi), note_template in _TEMP_NOTES:
                if lo <= temperature < hi:
                    explanation += " " + note_template.format(t=f"{temperature:.1f}")
                    break

        # 7. Build recommendations
        recs = list(_RECOMMENDATIONS.get(status, _RECOMMENDATIONS["fresh"]))

        # Fruit-specific tip
        fruit_tips = _FRUIT_TIPS.get(fruit, {})
        tip = fruit_tips.get(status, "")
        if tip:
            recs.append(tip)

        # Light-specific rec
        light_rec = _LIGHT_RECS.get(light_exposure or "shaded", "")
        if light_rec:
            recs.append(light_rec)

        # Airflow-specific rec
        airflow_rec = _AIRFLOW_RECS.get(airflow or "open_shelf", "")
        if airflow_rec:
            recs.append(airflow_rec)

        return LLMOutput(
            explanation=explanation.strip(),
            recommendations=recs[:3],
        )


# ── OpenAI LLM ────────────────────────────────────────────────────────────────

class OpenAILLM:
    SYSTEM_PROMPT = (
        "You are FreshSense, an AI fruit quality analyst. "
        "Given image analysis data and environment metadata, produce a concise "
        "explanation of the fruit's condition and 3 specific recommendations. "
        "Respond ONLY with valid JSON: "
        '{"explanation": "...", "recommendations": ["...", "...", "..."]}'
    )

    def __init__(self):
        try:
            from openai import AsyncOpenAI
            self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
        except ImportError:
            raise RuntimeError("Install openai: pip install openai")

    async def generate(
        self, cnn_output, ml_output, storage_method,
        temperature, purchase_date, humidity, light_exposure, airflow
    ) -> LLMOutput:
        user_content = (
            f"Fruit: {cnn_output.fruit_class}\n"
            f"Ripeness: {cnn_output.ripeness_stage.value}\n"
            f"CNN confidence: {cnn_output.confidence:.0%}\n"
            f"Color score: {cnn_output.visual_features.color_score:.2f}\n"
            f"Bruise ratio: {cnn_output.visual_features.bruise_ratio:.2f}\n"
            f"Mold detected: {cnn_output.visual_features.mold_detected}\n"
            f"Shelf life: {ml_output.shelf_life_days} days\n"
            f"Status: {ml_output.status.value}\n"
            f"Storage: {storage_method or 'unknown'}\n"
            f"Light exposure: {light_exposure or 'unknown'}\n"
            f"Airflow: {airflow or 'unknown'}\n"
            f"Outdoor temperature: {temperature or 'unknown'} °C\n"
            f"Outdoor humidity: {humidity or 'unknown'} %\n"
            f"Purchase date: {purchase_date or 'unknown'}"
        )
        response = await self.client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=[
                {"role": "system", "content": self.SYSTEM_PROMPT},
                {"role": "user", "content": user_content},
            ],
            response_format={"type": "json_object"},
            temperature=0.4,
        )
        data = json.loads(response.choices[0].message.content)
        return LLMOutput(
            explanation=data["explanation"],
            recommendations=data["recommendations"][:3],
        )


# ── Anthropic LLM ─────────────────────────────────────────────────────────────

class AnthropicLLM:
    SYSTEM_PROMPT = (
        "You are FreshSense, an AI fruit quality analyst. "
        "Respond ONLY with valid JSON: "
        '{"explanation": "...", "recommendations": ["...", "...", "..."]}'
    )

    def __init__(self):
        try:
            import anthropic
            self.client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        except ImportError:
            raise RuntimeError("Install anthropic: pip install anthropic")

    async def generate(
        self, cnn_output, ml_output, storage_method,
        temperature, purchase_date, humidity, light_exposure, airflow
    ) -> LLMOutput:
        user_content = (
            f"Fruit: {cnn_output.fruit_class}, ripeness: {cnn_output.ripeness_stage.value}, "
            f"shelf life: {ml_output.shelf_life_days} days, status: {ml_output.status.value}, "
            f"storage: {storage_method}, light: {light_exposure}, airflow: {airflow}, "
            f"outdoor temp: {temperature}°C, humidity: {humidity}%"
        )
        message = self.client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=512,
            system=self.SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_content}],
        )
        data = json.loads(message.content[0].text)
        return LLMOutput(
            explanation=data["explanation"],
            recommendations=data["recommendations"][:3],
        )


# ── Factory ───────────────────────────────────────────────────────────────────

def load_llm() -> StubLLM | OpenAILLM | AnthropicLLM:
    provider = settings.LLM_PROVIDER.lower()
    if provider == "openai":    return OpenAILLM()
    if provider == "anthropic": return AnthropicLLM()
    return StubLLM()


llm_service = load_llm()
