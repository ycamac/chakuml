.PHONY: dev-ml dev-backend dev-frontend dev-all test-contracts lint validate

dev-ml:
	cd ml && bash startup.sh

dev-backend:
	cd backend && uvicorn app.main:app --reload --port 8000

dev-frontend:
	cd frontend && npm run dev

dev-all:
	make dev-ml & make dev-backend & make dev-frontend

test-contracts:
	cd tests/contracts && pytest -v

lint:
	ruff check backend/ ml/

validate:
	bash tools/validate.sh
