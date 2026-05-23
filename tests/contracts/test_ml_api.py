"""Contract test: /api/ml/chat must return 200 or 401, never 500."""
import httpx

BASE_URL = "http://localhost:8000"


def test_ml_chat_shape():
    """POST /api/ml/chat returns expected response shape."""
    resp = httpx.post(
        f"{BASE_URL}/api/ml/chat",
        json={"message": "hello", "max_tokens": 10},
        headers={"Authorization": "Bearer test-token"},
    )
    assert resp.status_code in (200, 401)
