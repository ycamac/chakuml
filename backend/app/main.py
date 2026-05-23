"""FastAPI application factory."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

from app.routers import ml, db

load_dotenv()

app = FastAPI(title="Chaku API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("API_CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ml.router, prefix="/api/ml", tags=["ml"])
app.include_router(db.router, prefix="/api/db", tags=["db"])


@app.get("/health")
async def health():
    return {"status": "ok"}
