"""ML environment config — single source of truth for paths and URLs."""
from dotenv import load_dotenv
import os

load_dotenv()

LLAMA_BASE_URL: str = os.getenv("LLAMA_BASE_URL", "http://127.0.0.1:8080/v1")
ML_MODELS_DIR: str = os.getenv("ML_MODELS_DIR", "./models")
CHAT_MODEL_PATH: str = os.getenv("CHAT_MODEL_PATH", "./models/chat.gguf")
