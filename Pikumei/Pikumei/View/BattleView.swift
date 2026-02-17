//
//  BattleView.swift
//  Pikumei
//

import SwiftUI
import Supabase

/// バトル画面（仮）
struct BattleView: View {
    @State private var connectionStatus: String?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("バトル（準備中）")
                    .font(.headline)

                // Supabase 接続テスト（確認後に削除）
                connectionTestSection
            }
            .navigationTitle("バトル")
        }
    }

    // MARK: - 接続テスト（確認後に削除）

    private var connectionTestSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await testConnection() }
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Supabase 接続テスト")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isTesting)

            if let status = connectionStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(status.contains("OK") ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private func testConnection() async {
        isTesting = true
        connectionStatus = nil

        let client = SupabaseClientProvider.shared

        do {
            try await client.auth.signInAnonymously()
            let userId = try await client.auth.session.user.id

            try await client
                .from("monsters")
                .select("classification_label")
                .limit(1)
                .execute()

            connectionStatus = "OK: 接続成功\nUser: \(userId.uuidString.prefix(8))..."
        } catch {
            connectionStatus = "NG: \(error.localizedDescription)"
        }

        isTesting = false
    }
}

#Preview {
    BattleView()
}
