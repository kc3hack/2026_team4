//
//  MonsterScanViewModel.swift
//  Pikumei
//

import Combine
import SwiftData
import SwiftUI

/// モンスタースキャン画面の状態管理と処理オーケストレーション
@MainActor
class MonsterScanViewModel: ObservableObject {
    @Published var phase: ScanPhase = .camera
    @Published var cutoutImage: UIImage?
    @Published var errorMessage: String?
    @Published var showPreview = false
    @Published var lastSavedMonster: Monster?
    @Published var uploadError: String?
    
    let cameraManager = CameraManager()
    private var isConfigured = false
    
    let monsterClassifier = MonsterClassifier()
    
    func startCamera() {
        if !isConfigured {
            cameraManager.configure()
            isConfigured = true
        }
        cameraManager.startSession()
    }
    
    func stopCamera() {
        cameraManager.stopSession()
    }
    
    /// 撮影 → 前景検出 → 切り抜き → SwiftData に保存
    func captureAndProcess(modelContext: ModelContext) {
        Task {
            phase = .processing
            errorMessage = nil
            
            do {
                // 撮影
                let photo = try await cameraManager.capturePhoto()
                
                // タイプ分類
                let (monsterType, confidence) = try monsterClassifier.classify(image: photo)
                print("monsterType: \(monsterType), confidence: \(confidence * 100)%")
                
                // スキャン成功時に即保存
                let cutout = try await SubjectDetector.detectAndCutout(from: photo)
                let store = MonsterStore(modelContext: modelContext)
                try store.save(image: cutout, label: monsterType, confidence: confidence)

                // ローカル保存したモンスターを取得（Supabase アップロードは名前入力後に行う）
                let monsters = try store.fetchAll()
                if let latest = monsters.first {
                    lastSavedMonster = latest
                }

                cutoutImage = cutout
                showPreview = true
            } catch {
                print("⚠️ スキャンエラー: \(error)")
                errorMessage = error.localizedDescription
                phase = .result
            }
        }
    }
    
    /// 名前確定後に Supabase にアップロードする
    func uploadMonster(monster: Monster) {
        Task {
            do {
                let syncService = MonsterSyncService()
                try await syncService.upload(monster: monster)
            } catch {
                print("⚠️ アップロードエラー: \(error)")
                uploadError = "アップロードに失敗しました: \(error.localizedDescription)"
            }
        }
    }

    func retry() {
        showPreview = false
        cutoutImage = nil
        lastSavedMonster = nil
        errorMessage = nil
        uploadError = nil
        phase = .camera
    }
}
