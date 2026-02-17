//
//  SupabaseClient.swift
//  Pikumei
//

import Foundation
import Supabase

/// Supabase クライアントのシングルトン
/// 接続情報は Secrets.swift に記載（git 管理対象外）
enum SupabaseClientProvider {

    static let shared = SupabaseClient(
        supabaseURL: URL(string: Secrets.supabaseURL)!,
        supabaseKey: Secrets.supabaseAnonKey
    )
}
