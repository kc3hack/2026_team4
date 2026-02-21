//
//  BattleHistoryRowComponent.swift
//  Pikumei
//

import SwiftUI
import SwiftData

/// バトル履歴リストの1行分を表示するコンポーネント
struct BattleHistoryRowComponent: View {
    let history: BattleHistory

    var body: some View {
        HStack(spacing: 12) {
            // 相手サムネイル
            if let data = history.opponentThumbnail,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.gray.opacity(0.5))
            }

            // 相手モンスター名 + タイプ
            VStack(alignment: .leading, spacing: 2) {
                Text(history.opponentName ?? "???")
                    .font(.custom("DotGothic16-Regular", size: 14))
                    .foregroundStyle(Color.pikumeiNavy)
                    .lineLimit(1)

                TypeLabelComponent(
                    type: history.opponentType,
                    text: history.opponentType.displayName,
                    iconSize: 14,
                    fontSize: 11
                )
            }

            Spacer()

            // WIN / LOSE バッジ
            Text(history.isWin ? "WIN" : "LOSE")
                .font(.custom("RocknRollOne-Regular", size: 12))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(history.isWin ? .green : .red)
                )

            // 日付
//            Text(history.battleDate, format: .dateTime.month().day())
//                .font(.custom("DotGothic16-Regular", size: 11))
//                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        BattleHistoryRowComponent(
            history: BattleHistory(
                isWin: true,
                myType: .fire,
                myName: "ほのおくん",
                opponentType: .water,
                opponentName: "みずちゃん"
            )
        )
        BattleHistoryRowComponent(
            history: BattleHistory(
                isWin: false,
                myType: .leaf,
                myName: "くさもん",
                opponentType: .bird,
                opponentName: "とりさん"
            )
        )
    }
}
