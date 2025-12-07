import SwiftUI
import Charts

struct ElectiveDetailView: View {
    let elective: Elective
    @StateObject private var viewModel: ElectiveDetailViewModel
    @State private var showOptimizeSheet = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showAIAssistantSheet = false
    @State private var selectedGroupNumber: Int?
    @State private var showGroupStudents = false
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?
    @State private var showManageGroups = false
    @Environment(\.dismiss) var dismiss
    
    init(elective: Elective) {
        self.elective = elective
        _viewModel = StateObject(wrappedValue: ElectiveDetailViewModel(elective: elective))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(elective.name)
                        .font(.title.bold())
                    
                    Text(elective.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(elective.period, systemImage: "calendar")
                        Spacer()
                        Label(elective.teacherName, systemImage: "person.circle")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Statistics Cards
                HStack(spacing: 12) {
                    StatCard(
                        title: "Registered",
                        value: "\(elective.currentStudents)",
                        icon: "person.2.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Available",
                        value: "\(elective.availableSlots)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Fill Rate",
                        value: "\(Int(elective.fillPercentage * 100))%",
                        icon: "chart.bar.fill",
                        color: .orange
                    )
                }
                
                // Registration Trend Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Registration Trend")
                            .font(.headline)
                        
                        Spacer()
                        
                        if let predicted = viewModel.predictedFinalCount {
                            Text("Predicted: \(predicted)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !viewModel.dailyRegistrations.isEmpty {
                        let minDate = viewModel.dailyRegistrations.map { $0.date }.min() ?? Date()
                        let maxDate = viewModel.dailyRegistrations.map { $0.date }.max() ?? Date()
                        
                        Chart {
                            ForEach(viewModel.dailyRegistrations) { data in
                                // Area under the line with gradient
                                AreaMark(
                                    x: .value("Date", data.date),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                // Main line
                                LineMark(
                                    x: .value("Date", data.date),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(.blue)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(.catmullRom)
                                
                                // Points on the line
                                PointMark(
                                    x: .value("Date", data.date),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(.blue)
                                .symbolSize(80)
                            }
                        }
                        .frame(height: 200)
                        .chartXScale(domain: minDate...maxDate)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day(), anchor: .top)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .chartYScale(domain: 0...(viewModel.dailyRegistrations.map { $0.count }.max() ?? 10))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("No registration data yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Data will appear as students register")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Group Distribution
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Group Distribution")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showManageGroups = true }) {
                            Label("Manage", systemImage: "gearshape")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        if let balance = viewModel.groupBalance {
                            Text("Balance: \(String(format: "%.1f", balance.balanceCoefficient))")
                                .font(.caption)
                                .foregroundColor(balance.balanceCoefficient < 5 ? .green : .orange)
                                .padding(.leading, 8)
                        }
                    }
                    
                    if let balance = viewModel.groupBalance {
                        ForEach(balance.groups) { group in
                            Button(action: {
                                selectedGroupNumber = group.number
                                showGroupStudents = true
                            }) {
                                HStack {
                                    Text("Group \(group.number)")
                                        .font(.subheadline.weight(.medium))
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Text("\(group.studentCount)")
                                            .font(.title3.bold())
                                            .foregroundColor(.blue)
                                        Text("students")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button(action: { showOptimizeSheet = true }) {
                            Label("Re-optimize Distribution", systemImage: "wand.and.stars")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    } else if elective.numberOfGroups ?? 0 > 0 {
                        // Show empty groups
                        ForEach(1...(elective.numberOfGroups ?? 2), id: \.self) { groupNumber in
                            HStack {
                                Text("Group \(groupNumber)")
                                    .font(.subheadline.weight(.medium))
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("0")
                                        .font(.title3.bold())
                                        .foregroundColor(.secondary)
                                    Text("students")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                        
                        if !viewModel.registrations.isEmpty {
                            VStack(spacing: 8) {
                                Button(action: { 
                                    Task {
                                        await autoDistributeStudents()
                                    }
                                }) {
                                    Label("Auto-Distribute Students", systemImage: "arrow.triangle.branch")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: { showOptimizeSheet = true }) {
                                    Label("Optimize Distribution", systemImage: "wand.and.stars")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "person.2.slash")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                
                                Text("No students to distribute yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // AI Assistant Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        Text("AI Assistant")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    Text("Get AI-powered insights and recommendations for managing your elective")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showAIAssistantSheet = true }) {
                        Label("Open AI Assistant", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Student List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Registered Students")
                        .font(.headline)
                    
                    if viewModel.registrations.isEmpty {
                        Text("No students registered yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.registrations) { registration in
                            StudentRegistrationRow(registration: registration)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Elective Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !viewModel.registrations.isEmpty {
                    Button(action: exportAllStudents) {
                        Label("Export All", systemImage: "square.and.arrow.up")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .disabled(isDeleting)
            }
        }
        .alert("Delete Elective", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteElective()
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(elective.name)'? This will also remove all student registrations and analytics data. This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Deleting elective...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
            }
        }
        .sheet(isPresented: $showOptimizeSheet) {
            OptimizeDistributionView(
                elective: elective,
                registrations: viewModel.registrations,
                onComplete: {
                    Task {
                        await viewModel.loadData()
                    }
                }
            )
        }
        .sheet(isPresented: $showAIAssistantSheet) {
            AIAssistantView(
                elective: elective,
                registrations: viewModel.registrations,
                dailyData: viewModel.dailyRegistrations
            )
        }
        .sheet(isPresented: $showGroupStudents) {
            if let groupNumber = selectedGroupNumber {
                GroupStudentsView(
                    elective: elective,
                    groupNumber: groupNumber,
                    students: viewModel.registrations.filter { $0.groupNumber == groupNumber }
                )
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showManageGroups) {
            ManageGroupsView(
                elective: elective,
                registrations: viewModel.registrations,
                onComplete: {
                    Task {
                        await viewModel.loadData()
                    }
                }
            )
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private func exportAllStudents() {
        let fileName = "\(elective.name.replacingOccurrences(of: " ", with: "_"))_All_Students.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Create CSV content with group information
        var csvText = "Student Name,Registration Date,Priority,Group,Status\n"
        
        for student in viewModel.registrations.sorted(by: { 
            if let g1 = $0.groupNumber, let g2 = $1.groupNumber {
                if g1 != g2 { return g1 < g2 }
            }
            return $0.studentName < $1.studentName
        }) {
            let name = student.studentName
            let date = student.registrationDate.formatted(date: .abbreviated, time: .omitted)
            let priority = student.priority.map { String($0) } ?? "N/A"
            let group = student.groupNumber.map { "Group \($0)" } ?? "Unassigned"
            let status = student.status.rawValue.capitalized
            
            csvText += "\"\(name)\",\"\(date)\",\"\(priority)\",\"\(group)\",\"\(status)\"\n"
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            exportFileURL = path
            showExportSheet = true
        } catch {
            print("❌ Error creating CSV: \(error)")
        }
    }
    
    private func autoDistributeStudents() async {
        do {
            try await FirebaseDatabaseService.shared.autoDistributeUnassignedStudents(electiveId: elective.id)
            await viewModel.loadData() // Reload data to show updated groups
        } catch {
            print("❌ Error auto-distributing students: \(error)")
        }
    }
    
    private func deleteElective() async {
        isDeleting = true
        
        do {
            try await viewModel.deleteElective()
            dismiss()
        } catch {
            print("❌ Error deleting elective: \(error)")
            // You might want to show an error alert here
        }
        
        isDeleting = false
    }
}

// MARK: - View Model
@MainActor
class ElectiveDetailViewModel: ObservableObject {
    @Published var registrations: [StudentRegistration] = []
    @Published var dailyRegistrations: [RegistrationAnalytics.DailyRegistration] = []
    @Published var predictedFinalCount: Int?
    @Published var groupBalance: RegistrationAnalytics.GroupBalance?
    
    private let elective: Elective
    private var databaseService: DatabaseService {
        return FirebaseDatabaseService.shared
    }
    
    init(elective: Elective) {
        self.elective = elective
    }
    
    func loadData() async {
        await loadRegistrations()
        await loadAnalytics()
    }
    
    func deleteElective() async throws {
        try await databaseService.deleteElective(id: elective.id)
        print("✅ Elective deleted successfully")
    }
    
    private func loadRegistrations() async {
        do {
            registrations = try await databaseService.fetchRegistrations(for: elective.id)
        } catch {
            print("Error loading registrations: \(error)")
        }
    }
    
    private func loadAnalytics() async {
        do {
            // Спробувати завантажити реальні дані з підколекції daily
            dailyRegistrations = try await databaseService.fetchDailyRegistrations(for: elective.id, days: 30)
            
            if dailyRegistrations.isEmpty {
                print("⚠️ No daily registration data found for elective \(elective.id)")
            } else {
                print("✅ Loaded \(dailyRegistrations.count) daily registration records")
                
                // Розрахувати прогноз на основі реальних даних
                predictedFinalCount = GroupDistributionAlgorithm.predictFinalCount(dailyData: dailyRegistrations)
            }
            
            // Calculate group balance from registrations
            calculateGroupBalance()
            
        } catch {
            print("❌ Error loading analytics: \(error)")
            dailyRegistrations = []
            predictedFinalCount = nil
        }
    }
    
    private func calculateGroupBalance() {
        guard let numberOfGroups = elective.numberOfGroups, numberOfGroups > 0 else {
            groupBalance = nil
            return
        }
        
        // Count students per group
        var groupCounts: [Int: Int] = [:]
        for groupNum in 1...numberOfGroups {
            groupCounts[groupNum] = 0
        }
        
        for registration in registrations {
            if let groupNum = registration.groupNumber {
                groupCounts[groupNum, default: 0] += 1
            }
        }
        
        // Create group info
        let groups = groupCounts.map { groupNum, count in
            RegistrationAnalytics.GroupBalance.Group(
                id: "group_\(groupNum)",
                number: groupNum,
                studentCount: count
            )
        }.sorted { $0.number < $1.number }
        
        // Calculate balance coefficient
        let counts = groups.map { $0.studentCount }
        let maxCount = counts.max() ?? 0
        let minCount = counts.min() ?? 0
        let balanceCoeff = Double(maxCount - minCount)
        
        groupBalance = RegistrationAnalytics.GroupBalance(
            groups: groups,
            balanceCoefficient: balanceCoeff
        )
        
        print("📊 Group balance calculated: \(balanceCoeff)")
    }
}

// MARK: - Components
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StudentRegistrationRow: View {
    let registration: StudentRegistration
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(registration.studentName)
                    .font(.subheadline.weight(.medium))
                
                HStack(spacing: 12) {
                    if let group = registration.groupNumber {
                        Label("Group \(group)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(registration.registrationDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            StatusBadge(status: registration.status)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct OptimizeDistributionView: View {
    @Environment(\.dismiss) var dismiss
    let elective: Elective
    let registrations: [StudentRegistration]
    let onComplete: () -> Void
    
    @State private var isOptimizing = false
    @State private var optimizedRegistrations: [StudentRegistration] = []
    @State private var balanceCoefficient: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isOptimizing {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Optimizing distribution...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if !optimizedRegistrations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Optimization Complete")
                            .font(.title2.bold())
                        
                        Text("Balance Coefficient: \(String(format: "%.1f", balanceCoefficient))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: applyOptimization) {
                            Text("Apply Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Optimize Group Distribution")
                            .font(.title2.bold())
                        
                        Text("This will redistribute students across groups to achieve optimal balance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: startOptimization) {
                            Text("Start Optimization")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
            .navigationTitle("Optimize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startOptimization() {
        isOptimizing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let result = GroupDistributionAlgorithm.optimizeDistribution(
                registrations: registrations,
                numberOfGroups: elective.numberOfGroups ?? 2,
                maxStudentsPerGroup: elective.maxStudents / (elective.numberOfGroups ?? 2)
            )
            
            optimizedRegistrations = result.0
            balanceCoefficient = result.1
            isOptimizing = false
        }
    }
    
    private func applyOptimization() {
        // Apply the optimized distribution
        let databaseService = FirebaseDatabaseService.shared
        Task {
            for registration in optimizedRegistrations {
                try? await databaseService.updateRegistration(registration)
            }
            
            onComplete()
            dismiss()
        }
    }
}

// MARK: - AI Assistant View
struct AIAssistantView: View {
    @Environment(\.dismiss) var dismiss
    let elective: Elective
    let registrations: [StudentRegistration]
    let dailyData: [RegistrationAnalytics.DailyRegistration]
    
    @State private var selectedTab = 0
    @State private var isGenerating = false
    @State private var insights: [AIInsight] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.largeTitle)
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Assistant")
                                    .font(.title2.bold())
                                
                                Text("Powered by intelligent analytics")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Get personalized insights and recommendations for \(elective.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    
                    // Quick Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Overview")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            QuickStatCard(
                                icon: "person.2.fill",
                                title: "Enrolled",
                                value: "\(registrations.count)",
                                color: .blue
                            )
                            
                            QuickStatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Trend",
                                value: trendStatus,
                                color: trendColor
                            )
                            
                            QuickStatCard(
                                icon: "gauge.high",
                                title: "Fill Rate",
                                value: "\(Int(elective.fillPercentage * 100))%",
                                color: .orange
                            )
                            
                            QuickStatCard(
                                icon: "person.3.fill",
                                title: "Groups",
                                value: "\(elective.numberOfGroups ?? 0)",
                                color: .green
                            )
                        }
                    }
                    
                    // AI Insights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Insights")
                            .font(.headline)
                        
                        if isGenerating {
                            HStack {
                                ProgressView()
                                Text("Generating insights...")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else if insights.isEmpty {
                            Button(action: generateInsights) {
                                Label("Generate AI Insights", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                        } else {
                            ForEach(insights) { insight in
                                InsightCard(insight: insight)
                            }
                            
                            Button(action: generateInsights) {
                                Label("Regenerate Insights", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var trendStatus: String {
        guard dailyData.count >= 2 else { return "N/A" }
        let recent = dailyData.suffix(3)
        let avg = Double(recent.map { $0.count }.reduce(0, +)) / Double(recent.count)
        return avg > 5 ? "Up" : avg > 2 ? "Steady" : "Slow"
    }
    
    private var trendColor: Color {
        let status = trendStatus
        return status == "Up" ? .green : status == "Steady" ? .orange : .red
    }
    
    private func generateInsights() {
        isGenerating = true
        insights = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            var generatedInsights: [AIInsight] = []
            
            // Insight 1: Registration Analysis
            let fillRate = elective.fillPercentage
            if fillRate < 0.3 {
                generatedInsights.append(AIInsight(
                    id: UUID().uuidString,
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    title: "Low Registration Rate",
                    description: "Only \(Int(fillRate * 100))% of spots are filled. Consider promoting your elective through campus channels or adjusting prerequisites.",
                    actionTitle: "View Marketing Tips",
                    priority: .high
                ))
            } else if fillRate > 0.8 {
                generatedInsights.append(AIInsight(
                    id: UUID().uuidString,
                    icon: "checkmark.seal.fill",
                    color: .green,
                    title: "Strong Interest",
                    description: "Your elective is \(Int(fillRate * 100))% full! Consider increasing capacity or creating a waitlist for interested students.",
                    actionTitle: nil,
                    priority: .info
                ))
            }
            
            // Insight 2: Group Distribution
            if let numberOfGroups = elective.numberOfGroups, numberOfGroups > 1 {
                let registeredCount = registrations.count
                let studentsPerGroup = registeredCount / numberOfGroups
                
                if studentsPerGroup < 5 {
                    generatedInsights.append(AIInsight(
                        id: UUID().uuidString,
                        icon: "person.2.badge.gearshape.fill",
                        color: .blue,
                        title: "Consider Reducing Groups",
                        description: "With \(registeredCount) students across \(numberOfGroups) groups, each group has only ~\(studentsPerGroup) students. Smaller groups may impact learning dynamics.",
                        actionTitle: "Optimize Groups",
                        priority: .medium
                    ))
                }
            }
            
            // Insight 3: Registration Trend
            if !dailyData.isEmpty {
                let recentDays = dailyData.suffix(5)
                let recentAvg = Double(recentDays.map { $0.count }.reduce(0, +)) / Double(recentDays.count)
                
                if recentAvg < 1 {
                    generatedInsights.append(AIInsight(
                        id: UUID().uuidString,
                        icon: "chart.line.downtrend.xyaxis",
                        color: .red,
                        title: "Registration Slowdown",
                        description: "Recent registration activity has decreased. Engage with students through email campaigns or office hours to boost interest.",
                        actionTitle: "Engagement Ideas",
                        priority: .high
                    ))
                }
            }
            
            // Insight 4: Time Analysis
            let daysUntilStart = Calendar.current.dateComponents([.day], from: Date(), to: elective.registrationEndDate).day ?? 0
            if daysUntilStart < 7 && fillRate < 0.5 {
                generatedInsights.append(AIInsight(
                    id: UUID().uuidString,
                    icon: "clock.badge.exclamationmark.fill",
                    color: .orange,
                    title: "Registration Closing Soon",
                    description: "Only \(daysUntilStart) days left for registration, but only \(Int(fillRate * 100))% of spots are filled. Send reminder emails to boost last-minute signups.",
                    actionTitle: "Send Reminder",
                    priority: .high
                ))
            }
            
            // Insight 5: Category Match
            generatedInsights.append(AIInsight(
                id: UUID().uuidString,
                icon: "star.fill",
                color: .purple,
                title: "Popular Categories",
                description: "Your elective covers \(elective.categories.joined(separator: ", ")). Students interested in these topics typically show high engagement.",
                actionTitle: nil,
                priority: .info
            ))
            
            insights = generatedInsights
            isGenerating = false
        }
    }
}

struct AIInsight: Identifiable {
    let id: String
    let icon: String
    let color: Color
    let title: String
    let description: String
    let actionTitle: String?
    let priority: Priority
    
    enum Priority {
        case high, medium, info
    }
}

struct InsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(insight.color)
                
                Text(insight.title)
                    .font(.headline)
                
                Spacer()
                
                if insight.priority == .high {
                    Text("HIGH")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(6)
                }
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let actionTitle = insight.actionTitle {
                Button(action: {}) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(insight.color)
                }
            }
        }
        .padding()
        .background(insight.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Group Students View
struct GroupStudentsView: View {
    @Environment(\.dismiss) var dismiss
    let elective: Elective
    let groupNumber: Int
    let students: [StudentRegistration]
    @State private var showShareSheet = false
    @State private var csvFileURL: URL?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(students) { student in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(student.studentName)
                                .font(.headline)
                            
                            HStack {
                                Text("Registered: \(student.registrationDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let priority = student.priority {
                                    Spacer()
                                    Text("Priority: \(priority)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Text("\(students.count) Students")
                        Spacer()
                    }
                }
            }
            .navigationTitle("Group \(groupNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportToCSV) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = csvFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func exportToCSV() {
        let fileName = "Group_\(groupNumber)_\(elective.name.replacingOccurrences(of: " ", with: "_")).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Create CSV content
        var csvText = "Student Name,Registration Date,Priority,Status\n"
        
        for student in students.sorted(by: { $0.studentName < $1.studentName }) {
            let name = student.studentName
            let date = student.registrationDate.formatted(date: .abbreviated, time: .omitted)
            let priority = student.priority.map { String($0) } ?? "N/A"
            let status = student.status.rawValue.capitalized
            
            csvText += "\"\(name)\",\"\(date)\",\"\(priority)\",\"\(status)\"\n"
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            csvFileURL = path
            showShareSheet = true
        } catch {
            print("❌ Error creating CSV: \(error)")
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Manage Groups View
struct ManageGroupsView: View {
    @Environment(\.dismiss) var dismiss
    let elective: Elective
    let registrations: [StudentRegistration]
    let onComplete: () -> Void
    
    @State private var numberOfGroups: Int
    @State private var showAddGroupAlert = false
    @State private var showDeleteGroupAlert = false
    @State private var groupToDelete: Int?
    @State private var isSaving = false
    @State private var showStudentMover = false
    @State private var studentToMove: StudentRegistration?
    @State private var localRegistrations: [StudentRegistration]
    
    init(elective: Elective, registrations: [StudentRegistration], onComplete: @escaping () -> Void) {
        self.elective = elective
        self.registrations = registrations
        self.onComplete = onComplete
        _numberOfGroups = State(initialValue: elective.numberOfGroups ?? 2)
        _localRegistrations = State(initialValue: registrations)
    }
    
    var groupedStudents: [Int: [StudentRegistration]] {
        var groups: [Int: [StudentRegistration]] = [:]
        for groupNum in 1...numberOfGroups {
            groups[groupNum] = localRegistrations.filter { $0.groupNumber == groupNum }
        }
        return groups
    }
    
    var unassignedStudents: [StudentRegistration] {
        localRegistrations.filter { $0.groupNumber == nil }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Groups Section
                Section {
                    ForEach(Array(1...numberOfGroups), id: \.self) { groupNum in
                        GroupManagementRow(
                            groupNumber: groupNum,
                            students: groupedStudents[groupNum] ?? [],
                            onDelete: {
                                groupToDelete = groupNum
                                showDeleteGroupAlert = true
                            },
                            onMoveStudent: { student in
                                studentToMove = student
                                showStudentMover = true
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("Groups (\(numberOfGroups))")
                        Spacer()
                        Button(action: { showAddGroupAlert = true }) {
                            Label("Add Group", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                        }
                    }
                }
                
                // Unassigned Students
                if !unassignedStudents.isEmpty {
                    Section {
                        ForEach(unassignedStudents) { student in
                            Button(action: {
                                studentToMove = student
                                showStudentMover = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(student.studentName)
                                            .font(.subheadline)
                                        Text("Not assigned")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } header: {
                        Text("Unassigned Students (\(unassignedStudents.count))")
                    }
                }
            }
            .navigationTitle("Manage Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Add Group", isPresented: $showAddGroupAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    addGroup()
                }
            } message: {
                Text("Add a new group? This will create Group \(numberOfGroups + 1).")
            }
            .alert("Delete Group", isPresented: $showDeleteGroupAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let group = groupToDelete {
                        deleteGroup(group)
                    }
                }
            } message: {
                if let group = groupToDelete, let students = groupedStudents[group] {
                    Text("Delete Group \(group)? \(students.count) student(s) will be unassigned.")
                }
            }
            .sheet(isPresented: $showStudentMover) {
                if let student = studentToMove,
                   let currentStudent = localRegistrations.first(where: { $0.id == student.id }) {
                    MoveStudentView(
                        student: currentStudent,
                        numberOfGroups: numberOfGroups,
                        currentGroup: currentStudent.groupNumber,
                        onMove: { newGroup in
                            moveStudent(currentStudent, to: newGroup)
                        }
                    )
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Saving changes...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    private func addGroup() {
        withAnimation {
            numberOfGroups += 1
        }
        print("➕ Added new group. Total groups: \(numberOfGroups)")
    }
    
    private func deleteGroup(_ groupNumber: Int) {
        withAnimation {
            // Update local state first
            for i in 0..<localRegistrations.count {
                if localRegistrations[i].groupNumber == groupNumber {
                    localRegistrations[i].groupNumber = nil
                    localRegistrations[i].status = .pending
                } else if let currentGroup = localRegistrations[i].groupNumber, currentGroup > groupNumber {
                    // Shift down group numbers
                    localRegistrations[i].groupNumber = currentGroup - 1
                }
            }
            
            // Update number of groups
            numberOfGroups -= 1
        }
        print("🗑️ Deleted group \(groupNumber). Total groups: \(numberOfGroups)")
    }
    
    private func moveStudent(_ student: StudentRegistration, to newGroup: Int?) {
        // Update local registrations
        if let index = localRegistrations.firstIndex(where: { $0.id == student.id }) {
            localRegistrations[index].groupNumber = newGroup
            localRegistrations[index].status = newGroup != nil ? .confirmed : .pending
            print("📝 Moved \(student.studentName) to \(newGroup.map { "Group \($0)" } ?? "Unassigned")")
        }
    }
    
    private func saveChanges() async {
        isSaving = true
        
        do {
            // Save all registration changes
            for registration in localRegistrations {
                // Only update if different from original
                if let original = registrations.first(where: { $0.id == registration.id }),
                   (original.groupNumber != registration.groupNumber || original.status != registration.status) {
                    try await FirebaseDatabaseService.shared.updateRegistration(registration)
                    print("✅ Updated: \(registration.studentName) → Group \(registration.groupNumber?.description ?? "Unassigned")")
                }
            }
            
            // Update elective with new number of groups
            var updatedElective = elective
            updatedElective.numberOfGroups = numberOfGroups
            try await FirebaseDatabaseService.shared.updateElective(updatedElective)
            
            await MainActor.run {
                isSaving = false
                onComplete()
                dismiss()
            }
        } catch {
            print("❌ Error saving changes: \(error)")
            await MainActor.run {
                isSaving = false
            }
        }
    }
}

// MARK: - Group Management Row
struct GroupManagementRow: View {
    let groupNumber: Int
    let students: [StudentRegistration]
    let onDelete: () -> Void
    let onMoveStudent: (StudentRegistration) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.blue)
                    
                    Text("Group \(groupNumber)")
                        .font(.headline)
                    
                    Text("(\(students.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 8) {
                    if students.isEmpty {
                        Text("No students in this group")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(students) { student in
                            Button(action: { onMoveStudent(student) }) {
                                HStack {
                                    Text(student.studentName)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Group", systemImage: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 28)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Move Student View
struct MoveStudentView: View {
    @Environment(\.dismiss) var dismiss
    let student: StudentRegistration
    let numberOfGroups: Int
    let currentGroup: Int?
    let onMove: (Int?) -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        onMove(nil)
                        dismiss()
                    }) {
                        HStack {
                            Text("Unassigned")
                                .foregroundColor(.primary)
                            Spacer()
                            if currentGroup == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text("Remove from groups")
                }
                
                Section {
                    ForEach(Array(1...numberOfGroups), id: \.self) { groupNum in
                        Button(action: {
                            onMove(groupNum)
                            dismiss()
                        }) {
                            HStack {
                                Text("Group \(groupNum)")
                                    .foregroundColor(.primary)
                                Spacer()
                                if currentGroup == groupNum {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Move to group")
                }
            }
            .navigationTitle("Move \(student.studentName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

