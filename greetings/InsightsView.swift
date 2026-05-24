import SwiftUI
import Charts

struct ChartTheme {
    let income: Color
    let expense: Color
    let expenseArea: Color
    let bar: Color
    let background: LinearGradient
    let text: Color
}

struct InsightsView: View {
    let transactions: [Transaction]
    let theme: ChartTheme

    // MARK: - Chart Data
    private struct MonthKey: Hashable { let year: Int; let month: Int }

    private var monthlyTotals: [(date: Date, income: Double, expense: Double)] {
        var buckets: [MonthKey: (income: Double, expense: Double, date: Date)] = [:]
        let calendar = Calendar.current
        for tx in transactions {
            let comps = calendar.dateComponents([.year, .month], from: tx.date)
            guard let year = comps.year, let month = comps.month else { continue }
            let key = MonthKey(year: year, month: month)
            let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? tx.date
            var entry = buckets[key] ?? (income: 0, expense: 0, date: firstOfMonth)
            if tx.kind == .income { entry.income += tx.amount } else { entry.expense += tx.amount }
            buckets[key] = entry
        }
        return buckets.values.sorted { $0.date < $1.date }.map { ($0.date, $0.income, $0.expense) }
    }

    private var categoryBreakdown: [(category: Transaction.Category, total: Double)] {
        var totals: [Transaction.Category: Double] = [:]
        for tx in transactions where tx.kind == .expense {
            totals[tx.category, default: 0] += tx.amount
        }
        return totals.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    GroupBox("Monthly Trend") {
                        Chart {
                            ForEach(monthlyTotals, id: \.date) { item in
                                LineMark(x: .value("Month", item.date), y: .value("Income", item.income))
                                    .foregroundStyle(theme.income)
                                LineMark(x: .value("Month", item.date), y: .value("Expenses", item.expense))
                                    .foregroundStyle(theme.expense)
                                AreaMark(x: .value("Month", item.date), y: .value("Expenses", item.expense))
                                    .foregroundStyle(theme.expenseArea)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                        .frame(height: 220)
                    }

                    GroupBox("Expenses by Category") {
                        Chart(categoryBreakdown, id: \.category) { item in
                            BarMark(x: .value("Total", item.total), y: .value("Category", item.category.rawValue))
                                .foregroundStyle(theme.bar.gradient)
                        }
                        .frame(height: max(180, CGFloat(categoryBreakdown.count) * 28))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Insights")
    }
}

#Preview {
    InsightsView(transactions: [
        Transaction(title: "Salary", amount: 3000, date: .now, kind: .income, category: .salary),
        Transaction(title: "Groceries", amount: 220, date: .now, kind: .expense, category: .groceries),
        Transaction(title: "Rent", amount: 1200, date: .now, kind: .expense, category: .rent)
    ], theme: ChartTheme(
        income: .blue,
        expense: .red,
        expenseArea: .red.opacity(0.2),
        bar: .green,
        background: LinearGradient(colors: [.gray, .white], startPoint: .topLeading, endPoint: .bottomTrailing),
        text: .primary
    ))
}
