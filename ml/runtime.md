# ML Runtime

## Requirements
- llama.cpp compiled with CUDA support
- RTX 4000 Ada (12 GB VRAM)
- Model file (GGUF) placed in `./models/` — never committed to git

## Start

```bash
make dev-ml
# or: bash ml/startup.sh
```

## Health check

```bash
curl http://localhost:8080/v1/health
```

## Key flags

| Flag       | Value | Description                                        |
|------------|-------|----------------------------------------------------|
| -ngl       | 35    | GPU layers — increase for larger models if VRAM allows |
| --ctx-size | 2048  | Context window                                     |
| --port     | 8080  | llama.cpp port                                     |

## Recommended GGUF models (Q4, fits in 12 GB)

- Llama 3.1 8B Q4  (~5 GB VRAM)
- Mistral 7B Q4    (~4 GB VRAM)
- Phi-3 Mini Q4    (~2 GB VRAM)
