"""LLM chat inference service."""
from ml.clients.llama import complete


async def run_chat(req) -> dict:
    """Run one chat completion against the local LLM."""
    raw = await complete(prompt=req.message, max_tokens=req.max_tokens)
    return {
        "reply": raw.get("content", ""),
        "tokens_used": raw.get("tokens_evaluated", 0),
    }
