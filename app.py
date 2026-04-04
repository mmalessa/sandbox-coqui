import base64
import os
import tempfile
from contextlib import asynccontextmanager
from typing import Optional

import torch
from fastapi import APIRouter, FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field

MODEL_NAME = "tts_models/multilingual/multi-dataset/xtts_v2"
USE_GPU = torch.cuda.is_available()

tts_engine = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global tts_engine
    from TTS.api import TTS
    tts_engine = TTS(model_name=MODEL_NAME)
    tts_engine.to("cuda" if USE_GPU else "cpu")
    yield
    tts_engine = None


app = FastAPI(
    title="Coqui XTTS v2 API",
    lifespan=lifespan,
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
)
router = APIRouter(prefix="/api")


class TTSRequest(BaseModel):
    text: str = Field(..., description="Text to synthesize")
    language: str = Field("pl", description="BCP-47 language code: pl, en, de, fr, es, it, pt, ru, nl, cs, ar, zh-cn, ja, hu, ko, hi, tr")
    speaker: Optional[str] = Field("Filip Traverse", description="Built-in speaker name (see GET /speakers). Ignored when speaker_wav_base64 is provided.")
    speaker_wav_base64: Optional[str] = Field(None, description="Base64-encoded reference WAV for zero-shot voice cloning (overrides speaker).")

    # Prosody
    speed: float = Field(1.0, ge=0.1, le=10.0, description="Speech rate multiplier (1.0 = normal, 0.5 = half speed, 2.0 = double speed).")

    # Autoregressive sampling
    temperature: float = Field(0.75, ge=0.01, le=2.0, description="Sampling temperature. Higher = more expressive / less stable.")
    length_penalty: float = Field(1.0, description="Autoregressive length penalty. >1 favors shorter outputs, <1 favors longer.")
    repetition_penalty: float = Field(5.0, ge=1.0, le=20.0, description="Penalty for token repetition. Higher reduces looping artifacts.")
    top_k: int = Field(50, ge=1, le=1000, description="Top-k tokens kept for sampling.")
    top_p: float = Field(0.85, ge=0.0, le=1.0, description="Nucleus (top-p) sampling threshold.")
    do_sample: bool = Field(True, description="Use stochastic sampling. False = greedy decoding (fast but monotone).")

    # Text handling
    enable_text_splitting: bool = Field(True, description="Split long texts into sentences before synthesis (recommended for long inputs).")



def _require_engine():
    if tts_engine is None:
        raise HTTPException(503, detail="Model not loaded yet. Try again in a moment.")


@router.post(
    "/tts",
    response_class=Response,
    responses={200: {"content": {"audio/wav": {}}, "description": "Generated WAV audio"}},
    summary="Generate speech",
)
async def synthesize(req: TTSRequest):
    """
    Generate a WAV audio file from the provided text using XTTS v2.

    Returns raw WAV bytes (`Content-Type: audio/wav`).
    """
    _require_engine()

    out_path = None
    speaker_wav_path = None

    try:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            out_path = tmp.name

        if req.speaker_wav_base64:
            try:
                wav_bytes = base64.b64decode(req.speaker_wav_base64, validate=True)
            except Exception:
                raise HTTPException(422, detail="speaker_wav_base64 is not valid base64.")
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_spk:
                tmp_spk.write(wav_bytes)
                speaker_wav_path = tmp_spk.name

        kwargs = dict(
            text=req.text,
            language=req.language,
            file_path=out_path,
            speed=req.speed,
            temperature=req.temperature,
            length_penalty=req.length_penalty,
            repetition_penalty=req.repetition_penalty,
            top_k=req.top_k,
            top_p=req.top_p,
            do_sample=req.do_sample,
            enable_text_splitting=req.enable_text_splitting,
        )

        if speaker_wav_path:
            kwargs["speaker_wav"] = speaker_wav_path
        else:
            kwargs["speaker"] = req.speaker

        tts_engine.tts_to_file(**kwargs)

        with open(out_path, "rb") as f:
            wav_data = f.read()

        return Response(content=wav_data, media_type="audio/wav")

    finally:
        if out_path and os.path.exists(out_path):
            os.unlink(out_path)
        if speaker_wav_path and os.path.exists(speaker_wav_path):
            os.unlink(speaker_wav_path)


@router.get("/speakers", summary="List available built-in speakers")
async def list_speakers():
    _require_engine()
    speaker_manager = tts_engine.synthesizer.tts_model.speaker_manager
    return {"speakers": list(speaker_manager.speakers.keys())}


@router.get("/languages", summary="List supported languages")
async def list_languages():
    _require_engine()
    languages = tts_engine.synthesizer.tts_model.config.languages
    return {"languages": languages}


@router.get("/health", summary="Health check")
async def health():
    return {
        "status": "ok",
        "model": MODEL_NAME,
        "gpu": USE_GPU,
        "device": "cuda" if USE_GPU else "cpu",
    }


app.include_router(router)
