"""Single Supabase client module — only place for DB I/O."""
from supabase import create_client, Client
from dotenv import load_dotenv
import os

load_dotenv()

_client: Client | None = None


def get_client() -> Client:
    """Return singleton Supabase client."""
    global _client
    if _client is None:
        _client = create_client(
            os.environ["SUPA_URL"],
            os.environ["SUPA_SERVICE_KEY"],
        )
    return _client


async def get_items(uid: str) -> list:
    """Fetch all items belonging to user uid."""
    client = get_client()
    resp = client.table("items").select("*").eq("user_id", uid).execute()
    return resp.data
