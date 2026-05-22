import { createBrowserClient } from '@supabase/ssr'

/** Auth-only Supabase client. Never use for table CRUD — use callDB() instead. */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPA_URL!,
    process.env.NEXT_PUBLIC_SUPA_ANON_KEY!
  )
}
