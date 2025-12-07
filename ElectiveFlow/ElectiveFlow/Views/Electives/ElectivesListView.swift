import SwiftUI

struct ElectivesListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ElectivesViewModel()
    @State private var showCreateSheet = false
    @State private var searchText = ""
    @State private var selectedPeriod: String?
    @State private var selectedCategories: Set<String> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search Bar
                    SearchBar(text: $searchText, placeholder: L10n.shared.text("electives.search", language: appState.selectedLanguage))
                        .padding(.horizontal)
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: L10n.shared.text("electives.all", language: appState.selectedLanguage), isSelected: selectedPeriod == nil) {
                                selectedPeriod = nil
                            }
                            
                            ForEach(viewModel.periods, id: \.self) { period in
                                FilterChip(title: translatePeriod(period), isSelected: selectedPeriod == period) {
                                    selectedPeriod = period
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Electives List
                    LazyVStack(spacing: 16) {
                        ForEach(filteredElectives) { elective in
                            NavigationLink(destination: ElectiveDetailView(elective: elective)) {
                                ElectiveCard(elective: elective, language: appState.selectedLanguage)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(L10n.shared.text("electives.my_electives", language: appState.selectedLanguage))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateElectiveView(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.loadElectives()
            }
            .task {
                await viewModel.loadElectives()
            }
        }
    }
    
    private var filteredElectives: [Elective] {
        var filtered = viewModel.electives
        
        if let period = selectedPeriod {
            filtered = filtered.filter { $0.period == period }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered
    }
    
    private func translatePeriod(_ period: String) -> String {
        if period.contains("Fall") || period.contains("Осінь") {
            let year = period.components(separatedBy: " ").last ?? ""
            return "\(L10n.shared.text("period.fall", language: appState.selectedLanguage)) \(year)"
        } else if period.contains("Spring") || period.contains("Весна") {
            let year = period.components(separatedBy: " ").last ?? ""
            return "\(L10n.shared.text("period.spring", language: appState.selectedLanguage)) \(year)"
        } else if period.contains("Summer") || period.contains("Літо") {
            let year = period.components(separatedBy: " ").last ?? ""
            return "\(L10n.shared.text("period.summer", language: appState.selectedLanguage)) \(year)"
        }
        return period
    }
}

// MARK: - View Model
@MainActor
class ElectivesViewModel: ObservableObject {
    @Published var electives: [Elective] = []
    @Published var periods: [String] = ["Fall 2025", "Spring 2026", "Summer 2026"]
    
    private var databaseService: DatabaseService {
        return FirebaseDatabaseService.shared
    }
    
    func loadElectives() async {
        do {
            electives = try await databaseService.fetchElectives()
        } catch {
            print("Error loading electives: \(error)")
        }
    }
    
    func createElective(_ elective: Elective) async {
        do {
            try await databaseService.createElective(elective)
            await loadElectives()
        } catch {
            print("Error creating elective: \(error)")
        }
    }
    
    func deleteElective(_ elective: Elective) async {
        do {
            try await databaseService.deleteElective(id: elective.id)
            await loadElectives()
        } catch {
            print("Error deleting elective: \(error)")
        }
    }
}

// MARK: - Components
struct ElectiveCard: View {
    let elective: Elective
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(elective.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(translatePeriod(elective.period))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(elective.currentStudents)/\(elective.maxStudents)")
                        .font(.title3.bold())
                        .foregroundColor(elective.isFull ? .red : .primary)
                    
                    Text(L10n.shared.text("electives.students", language: language))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(elective.isFull ? Color.red : Color.blue)
                        .frame(width: geometry.size.width * elective.fillPercentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(elective.categories, id: \.self) { category in
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func translatePeriod(_ period: String) -> String {
        if period.contains("Fall") || period.contains("Осінь") {
            let year = period.components(separatedBy: " ").last ?? ""
            return "\(L10n.shared.text("period.fall", language: language)) \(year)"
        } else if period.contains("Spring") || period.contains("Весна") {
            let year = period.components(separatedBy: " ").last ?? ""
            return "\(L10n.shared.text("period.spring", language: language)) \(year)"
        } else if period.contains("Summer") || period.contains("Літо") {
            let year = period.components(separatedBy: " ").last ?? ""
            return "\(L10n.shared.text("period.summer", language: language)) \(year)"
        }
        return period
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}
