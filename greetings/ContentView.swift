//
//  ContentView.swift
//  greeting
//
//  Created by Farid on 20.05.26.
//

import SwiftUI
import UIKit

struct Transaction: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable { case income = "Income", expense = "Expense"; var id: String { rawValue } }
    enum Category: String, CaseIterable, Identifiable {
        case groceries = "Groceries", rent = "Rent", utilities = "Utilities", transport = "Transport", dining = "Dining", entertainment = "Entertainment", salary = "Salary", other = "Other"
        var id: String { rawValue }
    }
    let id = UUID()
    var title: String
    var amount: Double
    var date: Date
    var kind: Kind
    var category: Category
}

struct ContentView: View {
    @State private var transactions: [Transaction] = [
        Transaction(title: "Salary", amount: 1500, date: .now, kind: .income, category: .salary),
        Transaction(title: "Groceries", amount: 120.45, date: .now, kind: .expense, category: .groceries)
    ]
    
    enum Filter: String, CaseIterable, Identifiable { case all = "All", income = "Income", expense = "Expenses"; var id: String { rawValue } }
    @State private var selectedFilter: Filter = .all
    @State private var selectedCategory: Transaction.Category? = nil

    enum Theme: String, CaseIterable, Identifiable { case system = "System", light = "Light", dark = "Dark"; var id: String { rawValue } }
    @State private var selectedTheme: Theme = .system

    // New design palettes the user can choose from in Settings
    enum Design: String, CaseIterable, Identifiable {
        case system = "System"
        case darkGreen = "Dark Green"
        case blue = "Blue"
        case red = "Red"
        case japanese = "Japanese"
        case sydney = "Sydney Sweeney"
        var id: String { rawValue }
    }
    @State private var selectedDesign: Design = .system
    @State private var showSettings: Bool = false

    @State private var newTitle: String = ""
    @State private var newAmount: String = ""
    @State private var newKind: Transaction.Kind = .expense
    @State private var newCategory: Transaction.Category = .other
    @State private var showAddForm: Bool = false

    @State private var editingTransaction: Transaction? = nil
    @State private var showEditForm: Bool = false

    // Temporary fields for editing
    @State private var editTitle: String = ""
    @State private var editAmount: String = ""
    @State private var editKind: Transaction.Kind = .expense
    @State private var editCategory: Transaction.Category = .other
    @State private var editDate: Date = .now

    private var totalIncome: Double { transactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount } }
    private var totalExpenses: Double { transactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    private var balance: Double { totalIncome - totalExpenses }
    
    private var filteredTransactions: [Transaction] {
        let byKind: [Transaction]
        switch selectedFilter {
        case .all: byKind = transactions
        case .income: byKind = transactions.filter { $0.kind == .income }
        case .expense: byKind = transactions.filter { $0.kind == .expense }
        }
        if let cat = selectedCategory {
            return byKind.filter { $0.category == cat }
        } else {
            return byKind
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    HStack {
                        filterControl
                        Spacer(minLength: 12)
                        categoryFilterControl
                    }
                    summaryCard
                    listSection
                }
                        .padding()
                            }
                                    .preferredColorScheme(selectedTheme == .system ? nil : (selectedTheme == .light ? .light : .dark))
                                    .navigationTitle("")
            .toolbar {
                // Principal title so we can customize font/color for themes (Sydney uses a playful title)
                ToolbarItem(placement: .principal) {
                    let titleColor = titleColorForDesign(selectedDesign)
                    if selectedDesign == .sydney {
                        // Try to use a custom 'Satisfy' font if provided, otherwise fall back to rounded system
                        if UIFont(name: "Satisfy", size: 30) != nil {
                            Text("FinDuck")
                                .font(.custom("Satisfy", size: 30))
                                .foregroundColor(titleColor)
                        } else {
                            Text("FinDuck")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundColor(titleColor)
                        }
                    } else {
                        Text("FinDuck")
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .foregroundColor(titleColor)
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")

                    Spacer()

                    Button {
                        showAddForm = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("add-transaction")

                    Spacer()

                    NavigationLink {
                        InsightsView(transactions: transactions, theme: chartTheme)
                    } label: {
                        Label("Insights", systemImage: "chart.xyaxis.line")
                    }
                    .accessibilityLabel("Insights")
                }
            }
            .sheet(isPresented: $showAddForm) { addTransactionSheet }
            .sheet(isPresented: $showEditForm) { editTransactionSheet }
            .sheet(isPresented: $showSettings) { settingsSheet }
        }
    }
    private var filterControl: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(Filter.allCases) { f in
                Text(f.rawValue).tag(f)
            }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 4)
        .accessibilityLabel("Filter transactions")
    }

    // Computed gradient used for app background and small previews based on selected design
    private var backgroundGradient: LinearGradient {
        let colors = paletteColors(for: selectedDesign)
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func paletteColors(for design: Design) -> [Color] {
        switch design {
        case .system:
            return [Color(.systemBackground), Color(.secondarySystemBackground)]
        case .darkGreen:
            return [Color(red: 0.03, green: 0.2, blue: 0.13), Color(red: 0.06, green: 0.36, blue: 0.24)]
        case .blue:
            return [Color(red: 0.02, green: 0.45, blue: 0.75), Color(red: 0.18, green: 0.62, blue: 0.92)]
        case .red:
            return [Color(red: 0.55, green: 0.12, blue: 0.12), Color(red: 0.85, green: 0.38, blue: 0.38)]
        case .japanese:
            // Japanese flag inspired: white to Japan red
            return [Color.white, Color(red: 0.89, green: 0.0, blue: 0.13)]
        case .sydney:
            // Soft, feminine pink gradients to match Sydney theme; images overlay used when available
            return [Color(red: 1.00, green: 0.87, blue: 0.90), Color(red: 0.97, green: 0.76, blue: 0.86)]
        }
    }

    // Accent color derived from the design for small UI elements
    private func accentColor(for design: Design) -> Color {
        switch design {
        case .system: return Color.accentColor
        case .darkGreen: return Color(red: 0.10, green: 0.55, blue: 0.36)
        case .blue: return Color(red: 0.02, green: 0.45, blue: 0.75)
        case .red: return Color(red: 0.75, green: 0.18, blue: 0.18)
        case .japanese: return Color(red: 0.85, green: 0.45, blue: 0.12)
        case .sydney: return Color(red: 0.90, green: 0.60, blue: 0.70)
        }
    }

    // Attempt to load Sydney images from asset catalog named sydney1, sydney2, sydney3
    private func sydneyImages() -> [Image] {
        // Try a small range of numbered assets so adding new Sydney photos doesn't require code changes
        var images: [Image] = []
        for i in 1...6 {
            let name = "sydney\(i)"
            if let ui = UIImage(named: name) {
                images.append(Image(uiImage: ui))
            }
        }
        return images
    }

    // Settings sheet that exposes theme + design options with a small live preview
    private var settingsSheet: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                Form {
                    Section {
                        Text("App Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Section("Appearance") {
                        Picker("Appearance", selection: $selectedTheme) {
                            ForEach(Theme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Design") {
                        Picker("Design", selection: $selectedDesign) {
                            ForEach(Design.allCases) { d in
                                Text(d.rawValue).tag(d)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Choose design palette")

                        // Live preview — show Sydney images when the Sydney design is selected
                        HStack {
                            Text("Preview")
                            Spacer()
                            if selectedDesign == .sydney && !sydneyImages().isEmpty {
                                let imgs = sydneyImages()
                                HStack(spacing: 6) {
                                    ForEach(imgs.prefix(3).indices, id: \.self) { i in
                                        imgs[i]
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 70, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: paletteColors(for: selectedDesign), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 120, height: 44)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.06)))
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .tint(accentColor(for: selectedDesign))
            }
            .safeAreaInset(edge: .bottom) {
                Text("Make with ❤️ by DigitalTurkk")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
    }
    
    private var categoryFilterControl: some View {
        HStack(spacing: 8) {
            Picker("Category", selection: $selectedCategory) {
                Text("All Categories").tag(Transaction.Category?.none)
                ForEach(Transaction.Category.allCases) { cat in
                    Text(cat.rawValue).tag(Transaction.Category?.some(cat))
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Filter by category")

            // Quick clear button for category selection
            if selectedCategory != nil {
                Button {
                    selectedCategory = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(accentColor(for: selectedDesign))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Clear category filter")
            }
        }
    }

    // Theme-aware text color helper
    private func themedTextColor() -> Color {
        switch selectedTheme {
        case .dark: return .white
        case .light: return .black
        default: return .primary
        }
    }

    // FinDuck title color per design theme
    private func titleColorForDesign(_ design: Design) -> Color {
        switch design {
        case .darkGreen, .blue, .red:
            return .white
        case .japanese:
            return Color(red: 0.89, green: 0.0, blue: 0.13)
        case .sydney:
            return Color(red: 0.98, green: 0.78, blue: 0.88)
        case .system:
            return themedTextColor()
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overview").font(.headline).foregroundColor(themedTextColor())
                Spacer()
                Label(balance >= 0 ? "On track" : "Over budget", systemImage: balance >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(balance >= 0 ? .green : .orange)
            }
            HStack(spacing: 16) {
                Button {
                    selectedFilter = .income
                    selectedCategory = nil
                } label: {
                    summaryPill(title: "Income", value: totalIncome, color: .green, symbol: "arrow.down.circle.fill")
                }
                .buttonStyle(.plain)

                Button {
                    selectedFilter = .expense
                    selectedCategory = nil
                } label: {
                    summaryPill(title: "Expenses", value: totalExpenses, color: .red, symbol: "arrow.up.circle.fill")
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(themedTextColor().opacity(0.75))
                    Text(balance, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3).bold()
                        .foregroundColor(balance >= 0 ? themedTextColor() : Color.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            let ratio = max(0, min(1, totalIncome == 0 ? 0 : (totalIncome - totalExpenses) / max(totalIncome, 1)))
            ProgressView(value: ratio) {
                Text("Budget usage")
            } currentValueLabel: {
                Text(((1 - ratio) * 100), format: .percent.precision(.fractionLength(0)))
            }
            .tint(balance >= 0 ? .green : .orange)
        }
        .padding()
        .background(
            ZStack {
                LinearGradient(colors: paletteColors(for: selectedDesign).map { $0.opacity(0.95) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                if selectedDesign == .sydney {
                    if let ui = UIImage(named: "sydney1") {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .opacity(0.12)
                            .allowsHitTesting(false)
                    }
                    // subtle overlay to keep text readable
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.primary.opacity(0.02))
                        .allowsHitTesting(false)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05))
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var chartTheme: ChartTheme {
        let colors = paletteColors(for: selectedDesign)
        let primary = colors.first ?? .blue
        let secondary = colors.dropFirst().first ?? .red
        return ChartTheme(
            income: primary,
            expense: secondary,
            expenseArea: secondary.opacity(0.12),
            bar: secondary,
            background: LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            text: themedTextColor()
        )
    }
    
    private func summaryPill(title: String, value: Double, color: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: paletteColors(for: selectedDesign).map { $0.opacity(0.12) }, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.04))
        )
    }

    private var listSection: some View {
        Group {
            if filteredTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Transactions").font(.headline)
                    Text("Tap + to add your first income or expense.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Custom-styled list container with rounded background
                ZStack {
                    if selectedDesign == .sydney, let ui = UIImage(named: "sydney3") {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.12)
                            .clipped()
                            .allowsHitTesting(false)
                    }
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(paletteColors(for: selectedDesign).first?.opacity(selectedTheme == .dark ? 0.18 : 0.08) ?? Color(.secondarySystemBackground))
                        .allowsHitTesting(false)

                    List {
                            ForEach(filteredTransactions) { tx in
                                // Row with rounded background and theme-aware colors
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill((tx.kind == .expense ? Color.red : Color.green).opacity(0.15))
                                        Image(systemName: tx.kind == .expense ? "arrow.up" : "arrow.down")
                                            .foregroundStyle(tx.kind == .expense ? .red : .green)
                                    }
                                    .frame(width: 34, height: 34)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tx.title)
                                            .font(.headline)
                                            .foregroundColor(themedTextColor())
                                        Text(tx.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(themedTextColor().opacity(0.8))
                                        Text(tx.category.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(themedTextColor())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(paletteColors(for: selectedDesign).first?.opacity(0.12) ?? Color.secondary.opacity(0.15), in: Capsule())
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 6) {
                                        Text((tx.kind == .expense ? -tx.amount : tx.amount), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(tx.kind == .expense ? .red : .green)
                                        Button {
                                            beginEdit(tx)
                                        } label: {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.title3)
                                        }
                                        .buttonStyle(.borderless)
                                        .accessibilityLabel("Edit transaction")
                                    }
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(paletteColors(for: selectedDesign).first?.opacity(selectedTheme == .dark ? 0.12 : 0.06) ?? Color(.secondarySystemBackground))
                                )
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { beginEdit(tx) }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(tx.title), \(tx.kind.rawValue), amount \(tx.amount)")
                            }
                            .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
                .padding(.top, 6)
                .padding(.horizontal, 0)
            }
        }
    }

    private var addTransactionSheet: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title (e.g., Rent)", text: $newTitle)
                    TextField("Amount", text: $newAmount)
                        .keyboardType(.decimalPad)
                    Picker("Type", selection: $newKind) {
                        ForEach(Transaction.Kind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    Picker("Category", selection: $newCategory) {
                        ForEach(Transaction.Category.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("New Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { resetForm(); showAddForm = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addTransaction() }
                        .disabled(!canSubmit)
                }
            }
        }
    }

    private var editTransactionSheet: some View {
        NavigationStack {
            Form {
                Section("Edit Transaction") {
                    TextField("Title", text: $editTitle)
                    TextField("Amount", text: $editAmount)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $editDate, displayedComponents: .date)
                    Picker("Type", selection: $editKind) {
                        ForEach(Transaction.Kind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    Picker("Category", selection: $editCategory) {
                        ForEach(Transaction.Category.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancelEdit() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { applyEdit() }
                        .disabled(!canSubmitEdit)
                }
            }
        }
    }

    private var canSubmit: Bool {
        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount = Double(newAmount.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return false }
        return amount.isFinite
    }

    private func addTransaction() {
        guard let amount = Double(newAmount.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return }
        let tx = Transaction(title: newTitle.trimmingCharacters(in: .whitespacesAndNewlines), amount: amount, date: .now, kind: newKind, category: newCategory)
        transactions.insert(tx, at: 0)
        resetForm()
        showAddForm = false
    }

    private func beginEdit(_ tx: Transaction) {
        editingTransaction = tx
        editTitle = tx.title
        editAmount = String(format: "%.2f", tx.amount)
        editKind = tx.kind
        editCategory = tx.category
        editDate = tx.date
        showEditForm = true
    }

    private var canSubmitEdit: Bool {
        guard !editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount = Double(editAmount.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return false }
        return amount.isFinite
    }

    private func applyEdit() {
        guard let original = editingTransaction else { return }
        guard let amount = Double(editAmount.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return }
        if let idx = transactions.firstIndex(where: { $0.id == original.id }) {
            transactions[idx].title = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            transactions[idx].amount = amount
            transactions[idx].kind = editKind
            transactions[idx].category = editCategory
            transactions[idx].date = editDate
        }
        cancelEdit()
    }

    private func cancelEdit() {
        showEditForm = false
        editingTransaction = nil
        editTitle = ""
        editAmount = ""
        editKind = .expense
        editCategory = .other
        editDate = .now
    }

    private func delete(at offsets: IndexSet) { transactions.remove(atOffsets: offsets) }

    private func resetForm() {
        newTitle = ""
        newAmount = ""
        newKind = .expense
        newCategory = .other
    }
}

#Preview {
    ContentView()
}
