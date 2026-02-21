import SwiftUI
import SwiftData
import Charts

struct BattleHistoryView: View {
    @Query(sort: \BattleHistory.battleDate, order: .reverse)
    private var histories: [BattleHistory]
    
    // 日時フォーマット用のプロパティ
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }
    
    var body: some View {
        Group {
            if histories.isEmpty {
                ContentUnavailableView(
                    "バトル履歴がありません",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("バトルをするとここに記録されます")
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        historyListSection
                        summarySection
                        winRateChartSection
                        typeMatchupChartSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("バトル履歴")
        .background(
            Image("back_splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
    
    // MARK: - バトル履歴リスト
    private var historyListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最新の履歴")
                .font(.custom("RocknRollOne-Regular", size: 16))
                .foregroundStyle(Color.pikumeiNavy)
            
            LazyVStack(spacing: 0) {
                ForEach(histories) { history in
                    HStack(alignment: .center, spacing: 12) {
                        // 左側：名前、アイコン、WIN/LOSEバッジ
                        BattleHistoryRowComponent(history: history)
                        
                        Spacer()
                        
                        // 右側：新しい日時（yyyy/MM/dd HH:mm）
                        Text(dateFormatter.string(from: history.battleDate))
                            .font(.custom("DotGothic16-Regular", size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    
                    if history.id != histories.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.85))
        )
    }
    
    // MARK: - 戦績サマリー
    private var summarySection: some View {
        let summary = BattleHistoryViewModel.summary(from: histories)
        return HStack(spacing: 0) {
            SummaryItem(title: "合計", value: "\(summary.totalBattles)", color: .pikumeiNavy)
            SummaryItem(title: "勝利", value: "\(summary.wins)", color: .green)
            SummaryItem(title: "敗北", value: "\(summary.losses)", color: .red)
            SummaryItem(title: "勝率", value: "\(Int(summary.winRate * 100))%", color: .orange)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.85))
        )
    }
    
    // MARK: - 勝率推移グラフ
    private var winRateChartSection: some View {
        let trend = BattleHistoryViewModel.winRateTrend(from: histories)
        return VStack(alignment: .leading, spacing: 8) {
            Text("勝率推移")
                .font(.custom("RocknRollOne-Regular", size: 16))
                .foregroundStyle(Color.pikumeiNavy)
            
            Chart(trend) { point in
                LineMark(
                    x: .value("バトル", point.id),
                    y: .value("勝率", point.winRate * 100)
                )
                .foregroundStyle(.orange)
                
                PointMark(
                    x: .value("バトル", point.id),
                    y: .value("勝率", point.winRate * 100)
                )
                .foregroundStyle(.orange)
                .symbolSize(30)
            }
            .frame(height: 180)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)%")
                                .font(.custom("DotGothic16-Regular", size: 10))
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.85))
        )
    }
    
    // MARK: - タイプ別戦績グラフ
    private var typeMatchupChartSection: some View {
        let stats = BattleHistoryViewModel.typeMatchupStats(from: histories)
        return VStack(alignment: .leading, spacing: 8) {
            Text("タイプ別戦績")
                .font(.custom("RocknRollOne-Regular", size: 16))
                .foregroundStyle(Color.pikumeiNavy)
            
            Chart(stats) { stat in
                BarMark(
                    x: .value("タイプ", stat.opponentType.displayName),
                    y: .value("回数", stat.count)
                )
                .foregroundStyle(stat.isWin ? .green : .red)
            }
            .frame(height: 180)
            .chartForegroundStyleScale([
                "勝利": .green,
                "敗北": .red,
            ])
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.85))
        )
    }
}

private struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("RocknRollOne-Regular", size: 20))
                .foregroundStyle(color)
            Text(title)
                .font(.custom("DotGothic16-Regular", size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        BattleHistoryView()
            .modelContainer(for: BattleHistory.self, inMemory: true)
    }
}
