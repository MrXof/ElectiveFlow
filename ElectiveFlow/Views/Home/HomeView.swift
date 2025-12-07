import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var electivesViewModel = ElectivesViewModel()
    @State private var showCreateElectiveSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(L10n.shared.text("home.hello", language: appState.selectedLanguage)), \(appState.currentUser?.name ?? "User")!")
                            .font(.largeTitle.bold())
                        
                        Text(appState.currentUser?.role == .teacher 
                             ? L10n.shared.text("home.teacher_dashboard", language: appState.selectedLanguage)
                             : L10n.shared.text("home.student_dashboard", language: appState.selectedLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if appState.currentUser?.role == .teacher {
                        teacherDashboard
                    } else {
                        studentDashboard
                    }
                    
                    // Latest News Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.shared.text("home.latest_news", language: appState.selectedLanguage))
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        if viewModel.news.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.news.prefix(5)) { newsItem in
                                        NewsCardCompact(news: newsItem)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                viewModel.setUser(appState.currentUser)
                await viewModel.loadData()
            }
            .onChange(of: appState.currentUser) { newUser in
                viewModel.setUser(newUser)
                Task {
                    await viewModel.loadData()
                }
            }
            .sheet(isPresented: $showCreateElectiveSheet) {
                CreateElectiveView(viewModel: electivesViewModel)
            }
        }
    }
    
    private var teacherDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Analytics Snapshot
            VStack(alignment: .leading, spacing: 12) {
                Text("Analytics Snapshot")
                    .font(.title2.bold())
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    AnalyticsCard(
                        title: "Total Students",
                        value: "\(viewModel.totalStudents)",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    
                    AnalyticsCard(
                        title: "Your Electives",
                        value: "\(viewModel.teacherElectives.count)",
                        icon: "books.vertical.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
            
            // Your Electives Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your Electives")
                        .font(.title2.bold())
                    
                    Spacer()
                    
                    #if DEBUG
                    Button(action: {
                        Task {
                            await viewModel.generateTestDataForAllElectives()
                        }
                    }) {
                        HStack(spacing: 4) {
                            if viewModel.isGeneratingTestData {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                            } else {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                            }
                            Text(viewModel.isGeneratingTestData ? "Generating..." : "Test Data")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isGeneratingTestData)
                    #endif
                    
                    NavigationLink(destination: ElectivesListView()) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                if viewModel.teacherElectives.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        message: "No electives yet",
                        actionTitle: "Create First Elective",
                        action: {
                            showCreateElectiveSheet = true
                        }
                    )
                    .padding()
                } else {
                    ForEach(viewModel.teacherElectives.prefix(3)) { elective in
                        NavigationLink(destination: ElectiveDetailView(elective: elective)) {
                            ElectiveCardCompact(elective: elective)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var studentDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recommended Electives
            VStack(alignment: .leading, spacing: 12) {
                Text("Recommended for You")
                    .font(.title2.bold())
                    .padding(.horizontal)
                
                if viewModel.recommendedElectives.isEmpty {
                    Text("Complete your profile to get recommendations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.recommendedElectives.prefix(3)) { elective in
                        NavigationLink(destination: StudentElectiveDetailView(elective: elective)) {
                            ElectiveCardCompact(elective: elective)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
            }
            
            // My Registrations
            VStack(alignment: .leading, spacing: 12) {
                Text("My Electives")
                    .font(.title2.bold())
                    .padding(.horizontal)
                
                if viewModel.studentRegistrations.isEmpty {
                    EmptyStateView(
                        icon: "book",
                        message: "No registrations yet",
                        actionTitle: "Browse Catalog",
                        action: {
                            // Navigate to StudentElectivesView (Catalog tab)
                            // This will be handled by tab selection
                        }
                    )
                    .padding()
                } else {
                    ForEach(viewModel.studentRegistrations.prefix(3)) { registration in
                        RegistrationCard(registration: registration)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - View Model
@MainActor
class HomeViewModel: ObservableObject {
    @Published var news: [UniversityNews] = []
    @Published var teacherElectives: [Elective] = []
    @Published var recommendedElectives: [Elective] = []
    @Published var studentRegistrations: [StudentRegistration] = []
    @Published var totalStudents: Int = 0
    @Published var isGeneratingTestData: Bool = false
    
    private var databaseService: DatabaseService {
        return FirebaseDatabaseService.shared
    }
    
    private var currentUser: User?
    
    func setUser(_ user: User?) {
        currentUser = user
    }
    
    func loadData() async {
        await loadNews()
        
        guard let user = currentUser else { return }
        
        if user.role == .teacher {
            await loadTeacherData(teacherId: user.id)
        } else {
            await loadStudentData(studentId: user.id)
        }
    }
    
    private func loadNews() async {
        do {
            news = try await databaseService.fetchUniversityNews()
        } catch {
            print("Error loading news: \(error)")
        }
    }
    
    private func loadTeacherData(teacherId: String) async {
        print("👨‍🏫 Loading teacher data for ID: \(teacherId)")
        do {
            // Завантажити тільки елективи цього вчителя
            let allElectives = try await databaseService.fetchElectives()
            print("📚 Total electives in database: \(allElectives.count)")
            
            for elective in allElectives {
                print("   - \(elective.name) (Teacher ID: \(elective.teacherId))")
            }
            
            teacherElectives = allElectives.filter { $0.teacherId == teacherId }
            print("✅ Filtered to \(teacherElectives.count) electives for this teacher")
            
            // Порахувати реальну кількість студентів у елективах вчителя
            totalStudents = teacherElectives.reduce(0) { $0 + $1.currentStudents }
            print("📊 Total students across all teacher electives: \(totalStudents)")
        } catch {
            print("❌ Error loading teacher data: \(error)")
        }
    }
    
    #if DEBUG
    func generateTestDataForAllElectives() async {
        isGeneratingTestData = true
        print("🧪 Generating test data for all teacher's electives...")
        
        guard !teacherElectives.isEmpty else {
            print("⚠️ No electives to generate data for")
            isGeneratingTestData = false
            return
        }
        
        for elective in teacherElectives {
            print("📊 Generating test data for: \(elective.name)")
            do {
                try await databaseService.generateTestDailyRegistrations(electiveId: elective.id)
                print("   ✅ Test data generated for \(elective.name)")
            } catch {
                print("   ❌ Error generating data for \(elective.name): \(error)")
            }
        }
        
        print("🎉 Test data generation complete for all electives!")
        
        // Reload data to reflect changes
        await loadData()
        isGeneratingTestData = false
    }
    #endif
    
    private func loadStudentData(studentId: String) async {
        do {
            // Завантажити реєстрації студента
            studentRegistrations = try await databaseService.fetchStudentRegistrations(studentId: studentId)
            print("✅ Loaded \(studentRegistrations.count) registrations for student \(studentId)")
            
            // Завантажити всі елективи для рекомендацій
            let allElectives = try await databaseService.fetchElectives()
            print("✅ Loaded \(allElectives.count) total electives")
            
            // Фільтрувати рекомендації на основі інтересів студента
            if let interests = currentUser?.interests, !interests.isEmpty {
                print("🔍 Student interests: \(interests)")
                recommendedElectives = allElectives.filter { elective in
                    // Перевірити, чи студент ще не зареєстрований на цей електив
                    let notRegistered = !studentRegistrations.contains { $0.electiveId == elective.id }
                    
                    // Перевірити, чи категорії елективу відповідають інтересам студента
                    let matchesInterests = !Set(elective.categories).isDisjoint(with: Set(interests))
                    
                    return notRegistered && matchesInterests && !elective.isFull
                }
            } else {
                // Якщо немає інтересів, показати просто доступні елективи
                print("⚠️ No interests set for student")
                recommendedElectives = allElectives.filter { elective in
                    let notRegistered = !studentRegistrations.contains { $0.electiveId == elective.id }
                    return notRegistered && !elective.isFull
                }
            }
            
            // Обмежити до 5 рекомендацій
            recommendedElectives = Array(recommendedElectives.prefix(5))
            print("✅ Recommended \(recommendedElectives.count) electives")
            
        } catch {
            print("❌ Error loading student data: \(error)")
        }
    }
}

// MARK: - Components
struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ElectiveCardCompact: View {
    let elective: Elective
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(elective.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(elective.period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(elective.currentStudents)/\(elective.maxStudents)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Progress bar with minimum threshold indicator
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 8)
                    
                    // Fill progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(elective.currentStudents >= 10 ? Color.blue : Color.red)
                        .frame(width: min(CGFloat(elective.fillPercentage) * 100, 100), height: 8)
                    
                    // Minimum threshold line (at 10 students)
                    let minThreshold = 10
                    let thresholdPercentage = CGFloat(minThreshold) / CGFloat(elective.maxStudents)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 2, height: 12)
                        .offset(x: thresholdPercentage * 100 - 1)
                }
                .frame(width: 100, height: 12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct NewsCardCompact: View {
    let news: UniversityNews
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURL = news.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(width: 250, height: 140)
                .clipped()
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(news.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                
                Text(news.publishedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 250)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RegistrationCard: View {
    let registration: StudentRegistration
    @State private var elective: Elective?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let elective = elective {
                    Text(elective.name)
                        .font(.headline)
                    
                    Text(elective.period)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text(registration.registrationDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: registration.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .task {
            await loadElective()
        }
    }
    
    private func loadElective() async {
        do {
            elective = try await FirebaseDatabaseService.shared.fetchElective(id: registration.electiveId)
        } catch {
            print("Error loading elective: \(error)")
        }
    }
}

struct StatusBadge: View {
    let status: StudentRegistration.RegistrationStatus
    
    var color: Color {
        switch status {
        case .confirmed: return .green
        case .pending: return .orange
        case .waitlist: return .red
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
