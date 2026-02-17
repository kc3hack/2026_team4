//
//  SupabaseClient.swift
//  Pikumei
//

import Foundation
import Supabase

/// Supabase クライアントのシングルトン
/// SPM で supabase-swift を追加後に使用可能になる
enum SupabaseClientProvider {

    private static let supabaseURL = URL(string: "https://airfliszrpeclsenkaxp.supabase.co")!
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpcmZsaXN6cnBlY2xzZW5rYXhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyNTU1NTMsImV4cCI6MjA4NjgzMTU1M30.ngibqzTDH-WnetZwZIlth8zk37fhC6vL1-L-s8z1vHs"

    static let shared = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )
}
