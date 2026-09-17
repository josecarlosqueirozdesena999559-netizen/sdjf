import Foundation
import Supabase

struct UserDefaultsLocalStorage: AuthLocalStorage {
    func store(key: String, value: Data) throws {
        UserDefaults.standard.set(value, forKey: key)
    }
    func retrieve(key: String) throws -> Data? {
        return UserDefaults.standard.data(forKey: key)
    }
    func remove(key: String) throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://wceyuvrftlykumctqhzq.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjZXl1dnJmdGx5a3VtY3RxaHpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1Nzc0MTEsImV4cCI6MjEwNTE1MzQxMX0.WC9mpFCAYM_LH-iDJ5mLLwjUz-WAErdZw8SuJhAg-Do",
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(storage: UserDefaultsLocalStorage())
    )
)
