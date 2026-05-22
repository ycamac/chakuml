"""Contract test: /api/db/items must return 200 or 401, never 500."""
import httpx

BASE_URL = "http://localhost:8000"


def test_db_items_shape():
    """GET /api/db/items returns 200 or 401, never 500."""
    resp = httpx.get(
        f"{BASE_URL}/api/db/items",
        headers={"Authorization": "Bearer test-token"},
    )
    assert resp.status_code in (200, 401)
