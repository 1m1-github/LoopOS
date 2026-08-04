from contextlib import asynccontextmanager
from concurrent.futures import ThreadPoolExecutor
import asyncio
import tempfile
from pathlib import Path
import torch
from fastapi import FastAPI, File, UploadFile, HTTPException, Body
from transformers import pipeline
import numpy as np

pipe = None
executor = ThreadPoolExecutor(max_workers=1)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pipe
    device = 0 if torch.cuda.is_available() else -1
    pipe = pipeline(
        "automatic-speech-recognition",
        model="nvidia/parakeet-rnnt-1.1b",
        device=device,
        torch_dtype=torch.float16 if device >= 0 else torch.float32,
    )
    yield
    executor.shutdown(wait=True)

app = FastAPI(lifespan=lifespan)

def _run(path: str):
    return pipe(path)

@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("audio/"):
        raise HTTPException(400, "audio file required")
    suffix = Path(file.filename or "audio").suffix or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=True) as tmp:
        tmp.write(await file.read())
        tmp.flush()
        loop = asyncio.get_running_loop()
        result = await loop.run_in_executor(executor, _run, tmp.name)
    return result

@app.get("/health")
async def health():
    return {"status": "ok", "model": "nvidia/parakeet-rnnt-1.1b"}

@app.post("/pcm")
async def pcm(body: bytes = Body(...)):
    if len(body) % 2 != 0:
        raise HTTPException(400, "odd length pcm")
    audio = np.frombuffer(body, dtype=np.int16).astype(np.float32) / 32768.0
    loop = asyncio.get_running_loop()
    result = await loop.run_in_executor(executor, lambda: pipe(audio))
    return result
