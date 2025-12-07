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
                await viewModel.loadData()
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
    
    private var databaseService: DatabaseService {
        return FirebaseDatabaseService.shared
    }
    
    func loadData() async {
        await loadNews()
        await loadElectives()
    }
    
    private func loadNews() async {
        do {
            news = try await databaseService.fetchUniversityNews()
        } catch {
            print("Error loading news: \(error)")
        }
    }
    
    private func loadElectives() async {
        do {
            let allElectives = try await databaseService.fetchElectives()
            teacherElectives = allElectives
            totalStudents = teacherElectives.reduce(0) { $0 + $1.currentStudents }
        } catch {
            print("Error loading electives: \(error)")
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
                
                ProgressView(value: elective.fillPercentage)
                    .frame(width: 60)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Registration")
                    .font(.headline)
                
                Text(registration.registrationDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: registration.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
