#!/bin/bash
# Pre-commit gate. Run before every commit.
set -e

echo "── Contract tests ──"
pytest tests/contracts/ -v

echo "── Lint backend ──"
ruff check backend/

echo "── Lint ml ──"
ruff check ml/

echo "── All checks passed ──"
