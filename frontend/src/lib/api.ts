const API_URL = process.env.NEXT_PUBLIC_API_URL ?? ''

/** Call a FastAPI /api/ml/* endpoint and return JSON. */
export async function callML(endpoint: string, body: unknown) {
  const res = await fetch(`${API_URL}/api/ml/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  if (!res.ok) throw new Error(`ML API error: ${res.status}`)
  return res.json()
}

/** Call a FastAPI /api/db/* endpoint and return JSON. */
export async function callDB(endpoint: string, body?: unknown) {
  const res = await fetch(`${API_URL}/api/db/${endpoint}`, {
    method: body ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!res.ok) throw new Error(`DB API error: ${res.status}`)
  return res.json()
}
