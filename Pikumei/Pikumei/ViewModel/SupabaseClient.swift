//
//  SupabaseClient.swift
//  Pikumei
//

import Foundation
import Supabase

/// Supabase クライアントのシングルトン
/// SPM で supabase-swift を追加後に使用可能になる
enum SupabaseClientProvider {

    private static let supabaseURL = URL(string: "https://osxadxaeisvecfhwwezc.supabase.co")!
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zeGFkeGFlaXN2ZWNmaHd3ZXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMzQ1MzEsImV4cCI6MjA4NjgxMDUzMX0.kw2xV8yQ6UuR1tRL137c4QK4rfRCCHedHRecDYBCGwA"

    static let shared = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )
}
