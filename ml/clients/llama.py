"""HTTP client for llama.cpp server."""
import httpx
from ml.config import LLAMA_BASE_URL


async def complete(prompt: str, max_tokens: int = 256) -> dict:
    """Send a completion request to llama.cpp and return raw response."""
    async with httpx.AsyncClient(timeout=60.0) as client:
        resp = await client.post(
            f"{LLAMA_BASE_URL}/completions",
            json={"prompt": prompt, "n_predict": max_tokens},
        )
        resp.raise_for_status()
        return resp.json()


async def health_check() -> bool:
    """Ping llama.cpp server; return True if reachable."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(f"{LLAMA_BASE_URL}/health")
            return resp.status_code == 200
    except Exception:
        return False
