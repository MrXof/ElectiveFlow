import SwiftUI

struct StudentElectivesView: View {
    @StateObject private var viewModel = StudentElectivesViewModel()
    @State private var searchText = ""
    @State private var selectedCategories: Set<String> = []
    @State private var showOnlyAvailable = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search Bar
                    SearchBar(text: $searchText, placeholder: "Search electives")
                        .padding(.horizontal)
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "All", isSelected: selectedCategories.isEmpty) {
                                selectedCategories.removeAll()
                            }
                            
                            ForEach(viewModel.allCategories, id: \.self) { category in
                                FilterChip(title: category, isSelected: selectedCategories.contains(category)) {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }
                            }
                            
                            Divider()
                                .frame(height: 20)
                            
                            FilterChip(title: "Available", isSelected: showOnlyAvailable) {
                                showOnlyAvailable.toggle()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recommended Section
                    if !viewModel.recommendedElectives.isEmpty && searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended for You")
                                .font(.title2.bold())
                                .padding(.horizontal)
                            
                            ForEach(viewModel.recommendedElectives.prefix(3)) { elective in
                                NavigationLink(destination: StudentElectiveDetailView(elective: elective)) {
                                    StudentElectiveCard(elective: elective, isRecommended: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // All Electives
                    VStack(alignment: .leading, spacing: 12) {
                        Text(searchText.isEmpty ? "All Electives" : "Search Results")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        if filteredElectives.isEmpty {
                            EmptySearchView()
                                .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredElectives) { elective in
                                    NavigationLink(destination: StudentElectiveDetailView(elective: elective)) {
                                        StudentElectiveCard(elective: elective, isRecommended: false)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Electives Catalog")
            .refreshable {
                await viewModel.loadElectives()
            }
            .task {
                await viewModel.loadElectives()
            }
        }
    }
    
    private var filteredElectives: [Elective] {
        var filtered = viewModel.allElectives
        
        if !selectedCategories.isEmpty {
            filtered = filtered.filter { elective in
                !Set(elective.categories).isDisjoint(with: selectedCategories)
            }
        }
        
        if showOnlyAvailable {
            filtered = filtered.filter { !$0.isFull }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
}

// MARK: - View Model
@MainActor
class StudentElectivesViewModel: ObservableObject {
    @Published var allElectives: [Elective] = []
    @Published var recommendedElectives: [Elective] = []
    @Published var allCategories: [String] = []
    @Published var studentInterests: [String] = []
    
    private var databaseService: DatabaseService {
        return FirebaseDatabaseService.shared
    }
    
    func loadElectives() async {
        do {
            allElectives = try await databaseService.fetchElectives()
            
            // Extract all unique categories
            allCategories = Array(Set(allElectives.flatMap { $0.categories })).sorted()
            
            // Calculate recommendations
            calculateRecommendations()
        } catch {
            print("Error loading electives: \(error)")
        }
    }
    
    private func calculateRecommendations() {
        // Mock student interests (in real app, would come from user profile)
        studentInterests = ["AI", "Programming", "Data Science"]
        
        // Use cosine similarity to recommend electives
        let recommendations = allElectives.map { elective -> (Elective, Double) in
            let similarity = GroupDistributionAlgorithm.cosineSimilarity(
                studentInterests: studentInterests,
                electiveCategories: elective.categories
            )
            return (elective, similarity)
        }
        
        recommendedElectives = recommendations
            .sorted { $0.1 > $1.1 }
            .filter { $0.1 > 0 }
            .map { $0.0 }
    }
}

// MARK: - Components
struct StudentElectiveCard: View {
    let elective: Elective
    let isRecommended: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(elective.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isRecommended {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(elective.teacherName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if elective.isFull {
                        Text("Full")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(6)
                    } else {
                        Text("\(elective.availableSlots) spots")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.green)
                    }
                }
            }
            
            Text(elective.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(elective.period, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < Int(elective.fillPercentage * 5) ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(elective.categories, id: \.self) { category in
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: isRecommended ? .blue.opacity(0.2) : .clear, radius: 8)
        )
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No electives found")
                .font(.headline)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
