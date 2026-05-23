"""Contract test: health endpoint must return 200."""
import httpx

BASE_URL = "http://localhost:8000"


def test_health():
    """GET /health returns 200 and status ok."""
    resp = httpx.get(f"{BASE_URL}/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
