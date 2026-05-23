# test-guard

## Owns
- tests/contracts/**
- tests/e2e/**
- tools/validate.sh

## Must NOT touch
- Feature code, schemas

## Purpose
Pre-commit gate. Updates contract tests when API or schema changes.
Fails if endpoint paths are duplicated or if clients (httpx, Supabase) are
copied across modules instead of using the shared singleton.

## Run
bash tools/validate.sh
