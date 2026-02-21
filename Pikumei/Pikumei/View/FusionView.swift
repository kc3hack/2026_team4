//
//  FusionView.swift
//  Pikumei
//
//  モンスター合体画面
//

import SwiftUI
import SwiftData

struct FusionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var vm = MonsterFusionViewModel()

    var body: some View {
        ZStack {
            Image("back_splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            switch vm.phase {
            case .selectFirst:
                selectionView(
                    title: "合体させるメイティを選んでください",
                    monsters: vm.fetchOwnMonsters(),
                    emptyMessage: "合体できるメイティがいません",
                    onSelect: { vm.selectFirst($0) }
                )
            case .selectSecond:
                selectionView(
                    title: "交換で手に入れたメイティを選んでください",
                    monsters: vm.fetchExchangedMonsters(),
                    emptyMessage: "交換で手に入れたメイティがいません",
                    onSelect: { vm.selectSecond($0) }
                )
            case .confirm:
                confirmView
            case .result(let monster):
                resultView(monster: monster)
            }
        }
        .navigationBarBackButtonHidden(hideDefaultBack)
        .toolbar {
            if showCustomBack {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.back()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            vm.setModelContext(modelContext)
        }
    }

    /// selectSecond / confirm では独自の「戻る」ボタン、result では戻るボタン自体を非表示
    private var hideDefaultBack: Bool {
        switch vm.phase {
        case .selectSecond, .confirm, .result:
            return true
        default:
            return false
        }
    }

    private var showCustomBack: Bool {
        switch vm.phase {
        case .selectSecond, .confirm:
            return true
        default:
            return false
        }
    }

    // MARK: - モンスター選択

    private func selectionView(
        title: String,
        monsters: [Monster],
        emptyMessage: String,
        onSelect: @escaping (Monster) -> Void
    ) -> some View {
        Group {
            if monsters.isEmpty {
                ContentUnavailableView(
                    emptyMessage,
                    systemImage: "photo.on.rectangle.angled"
                )
            } else {
                ScrollView {
                    Spacer(minLength: 100)
                    Text(title)
                        .font(.custom("RocknRollOne-Regular", size: 17))

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(monsters) { monster in
                            Button {
                                onSelect(monster)
                            } label: {
                                MonsterCardComponent(
                                    monster: monster,
                                    stats: monster.battleStats
                                )
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
    }

    // MARK: - 合体確認

    private var confirmView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 80)

                Text("この2体を合体しますか？")
                    .font(.custom("RocknRollOne-Regular", size: 17))

                // 素材モンスター表示
                HStack(spacing: 16) {
                    if let first = vm.firstMonster {
                        MonsterCardComponent(
                            monster: first,
                            stats: first.battleStats
                        )
                    }
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundStyle(.white)
                    if let second = vm.secondMonster {
                        MonsterCardComponent(
                            monster: second,
                            stats: second.battleStats
                        )
                    }
                }
                .padding(.horizontal, 8)

                // プレビューステータス
                if let preview = vm.previewStats {
                    VStack(spacing: 8) {
                        Text("合体後のステータス")
                            .font(.custom("RocknRollOne-Regular", size: 15))
                            .foregroundStyle(.white)
                        HStack(spacing: 16) {
                            fusionStatLabel("HP", value: preview.hp)
                            fusionStatLabel("ATK", value: preview.attack)
                            fusionStatLabel("S.ATK", value: preview.specialAttack)
                            fusionStatLabel("S.DEF", value: preview.specialDefense)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.4))
                    )
                }

                Text("※ 合体すると素材の2体は消えます")
                    .font(.custom("DotGothic16-Regular", size: 13))
                    .foregroundStyle(.white.opacity(0.7))

                BlueButtonComponent(title: "合体する") {
                    Task { await vm.fuse() }
                }
            }
            .padding()
        }
    }

    // MARK: - 合体結果

    private func resultView(monster: Monster) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("合体成功！")
                    .font(.custom("RocknRollOne-Regular", size: 24))
                    .foregroundStyle(.black)
                    .padding(.top, 20)

                if let uiImage = monster.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .white.opacity(0.3), radius: 12)
                }

                MonsterCardComponent(
                    monster: monster,
                    stats: monster.battleStats
                )
                .frame(maxWidth: 200)

                BlueButtonComponent(title: "とじる") {
                    vm.reset()
                    dismiss()
                }
            }
            .padding()
        }
    }

    // MARK: - ヘルパー

    private func fusionStatLabel(_ label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.custom("DotGothic16-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.7))
            Text("\(value)")
                .font(.custom("DotGothic16-Regular", size: 18))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack {
        FusionView()
    }
    .modelContainer(for: Monster.self, inMemory: true)
}
