//
//  BattleView.swift
//  Pikumei
//

import SwiftUI

/// バトル画面（仮）
struct BattleView: View {
    @StateObject private var testVM = SupabaseTestViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("バトル（準備中）")
                        .font(.headline)

                    // Supabase 接続テスト（確認後に削除）
                    connectionTestSection

                    Divider()

                    // 画像取得テスト（確認後に削除）
                    imageTestSection
                }
                .padding()
            }
            .navigationTitle("バトル")
        }
    }

    // MARK: - 接続テスト（確認後に削除）

    private var connectionTestSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await testVM.testConnection() }
            } label: {
                HStack {
                    if testVM.isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Supabase 接続テスト")
                }
            }
            .buttonStyle(.bordered)
            .disabled(testVM.isTesting)

            if let status = testVM.connectionStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(status.contains("OK") ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - 画像取得テスト（確認後に削除）

    private var imageTestSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await testVM.fetchImages() }
            } label: {
                HStack {
                    if testVM.isFetchingImages {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Supabase 画像取得テスト")
                }
            }
            .buttonStyle(.bordered)
            .disabled(testVM.isFetchingImages)

            if let error = testVM.fetchError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if !testVM.fetchedMonsters.isEmpty {
                Text("\(testVM.fetchedMonsters.count) 件取得")
                    .font(.caption)
                    .foregroundStyle(.green)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(testVM.fetchedMonsters) { monster in
                        VStack(spacing: 4) {
                            if let uiImage = monster.uiImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(.gray.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fill)
                                    .cornerRadius(8)
                                    .overlay(Text("?").font(.title))
                            }

                            Text(monster.classificationLabel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    BattleView()
}
