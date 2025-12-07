import SwiftUI
import Charts

struct ElectiveDetailView: View {
    let elective: Elective
    @StateObject private var viewModel: ElectiveDetailViewModel
    @State private var showOptimizeSheet = false
    
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
                if !viewModel.dailyRegistrations.isEmpty {
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
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // Group Balance
                if let balance = viewModel.groupBalance {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Group Distribution")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("Balance: \(String(format: "%.1f", balance.balanceCoefficient))")
                                .font(.caption)
                                .foregroundColor(balance.balanceCoefficient < 5 ? .green : .orange)
                        }
                        
                        ForEach(balance.groups) { group in
                            HStack {
                                Text("Group \(group.number)")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(group.studentCount) students")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray5))
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
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // Student List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Registered Students")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: exportToExcel) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }
                    
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
        .task {
            await viewModel.loadData()
        }
    }
    
    private func exportToExcel() {
        // Export functionality would be implemented here
        print("Exporting to Excel...")
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
    
    private func loadRegistrations() async {
        do {
            registrations = try await databaseService.fetchRegistrations(for: elective.id)
        } catch {
            print("Error loading registrations: \(error)")
        }
    }
    
    private func loadAnalytics() async {
        do {
            let analytics = try await databaseService.fetchAnalytics(for: elective.id)
            dailyRegistrations = analytics.dailyRegistrations
            predictedFinalCount = analytics.predictedFinalCount
            groupBalance = analytics.groupBalance
        } catch {
            print("Error loading analytics: \(error)")
            // Generate mock data for demonstration
            generateMockAnalytics()
        }
    }
    
    private func generateMockAnalytics() {
        // Generate sample daily registrations
        let calendar = Calendar.current
        let today = Date()
        
        dailyRegistrations = (0..<7).compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { return nil }
            return RegistrationAnalytics.DailyRegistration(
                id: UUID().uuidString,
                date: date,
                count: Int.random(in: 5...15)
            )
        }.reversed()
        
        // Calculate prediction
        predictedFinalCount = GroupDistributionAlgorithm.predictFinalCount(dailyData: dailyRegistrations)
        
        // Generate group balance
        if let numberOfGroups = elective.numberOfGroups {
            let groups = (1...numberOfGroups).map { groupNum in
                RegistrationAnalytics.GroupBalance.Group(
                    id: UUID().uuidString,
                    number: groupNum,
                    studentCount: Int.random(in: 8...12)
                )
            }
            
            let minCount = groups.map { $0.studentCount }.min() ?? 0
            let maxCount = groups.map { $0.studentCount }.max() ?? 0
            
            groupBalance = RegistrationAnalytics.GroupBalance(
                groups: groups,
                balanceCoefficient: Double(maxCount - minCount)
            )
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
