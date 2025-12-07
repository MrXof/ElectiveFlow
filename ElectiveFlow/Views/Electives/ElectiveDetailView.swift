import SwiftUI
import Charts

struct ElectiveDetailView: View {
    let elective: Elective
    @StateObject private var viewModel: ElectiveDetailViewModel
    @State private var showOptimizeSheet = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showAIAssistantSheet = false
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
                        Chart {
                            ForEach(viewModel.dailyRegistrations) { data in
                                LineMark(
                                    x: .value("Date", data.date),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                                
                                PointMark(
                                    x: .value("Date", data.date),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
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
                        
                        if let balance = viewModel.groupBalance {
                            Text("Balance: \(String(format: "%.1f", balance.balanceCoefficient))")
                                .font(.caption)
                                .foregroundColor(balance.balanceCoefficient < 5 ? .green : .orange)
                        }
                    }
                    
                    if let balance = viewModel.groupBalance {
                        ForEach(balance.groups) { group in
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
                                }
                            }
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
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
                            Button(action: { showOptimizeSheet = true }) {
                                Label("Distribute Students", systemImage: "wand.and.stars")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
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
        .task {
            await viewModel.loadData()
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
            
            // Спробувати завантажити баланс груп
            do {
                let analytics = try await databaseService.fetchAnalytics(for: elective.id)
                groupBalance = analytics.groupBalance
            } catch {
                print("⚠️ No group balance data found")
            }
            
        } catch {
            print("❌ Error loading analytics: \(error)")
            dailyRegistrations = []
            predictedFinalCount = nil
        }
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
