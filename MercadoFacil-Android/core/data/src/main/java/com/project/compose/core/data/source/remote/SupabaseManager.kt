package com.project.compose.core.data.source.remote

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.gotrue.Auth
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime

object SupabaseManager {
    private const val SUPABASE_URL = "https://wceyuvrftlykumctqhzq.supabase.co"
    private const val SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjZXl1dnJmdGx5a3VtY3RxaHpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1Nzc0MTEsImV4cCI6MjEwNTE1MzQxMX0.WC9mpFCAYM_LH-iDJ5mLLwjUz-WAErdZw8SuJhAg-Do"

    val client: SupabaseClient by lazy {
        createSupabaseClient(
            supabaseUrl = SUPABASE_URL,
            supabaseKey = SUPABASE_KEY
        ) {
            install(Auth)
            install(Postgrest)
            install(Realtime)
        }
    }
}
