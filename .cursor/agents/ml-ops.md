# ml-ops

## Owns
- ml/** (entirely)

## Must NOT touch
- database/, frontend/
- No logic inside backend/app/routers/ml.py

## Stack
- Python async, httpx for llama.cpp client
- llama.cpp HTTP API (OpenAI-compatible)
- scikit-learn for predictive models (optional)

## Conventions
- All LLM calls through `ml/clients/llama.py`
- Services in `ml/services/` — one file per concern
- No model weights in git — paths from `ml/config.py`
- Every function has a one-line English docstring
