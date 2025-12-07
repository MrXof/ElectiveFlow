import SwiftUI

struct NewsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NewsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.news.isEmpty {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 100)
                        } else {
                            EmptyNewsView()
                                .padding(.top, 100)
                        }
                    } else {
                        ForEach(viewModel.news) { newsItem in
                            NewsCard(news: newsItem)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(L10n.shared.text("news.university_news", language: appState.selectedLanguage))
            .refreshable {
                await viewModel.loadNews()
            }
            .task {
                await viewModel.loadNews()
            }
        }
    }
}

// MARK: - View Model
@MainActor
class NewsViewModel: ObservableObject {
    @Published var news: [UniversityNews] = []
    @Published var isLoading = false
    
    private var databaseService: DatabaseService {
        return FirebaseDatabaseService.shared
    }
    
    func loadNews() async {
        isLoading = true
        
        do {
            news = try await databaseService.fetchUniversityNews()
        } catch {
            print("Error loading news: \(error)")
            // Generate mock news for demo
            generateMockNews()
        }
        
        isLoading = false
    }
    
    private func generateMockNews() {
        news = [
            UniversityNews(
                id: UUID().uuidString,
                title: "New AI Research Lab Opens",
                description: "The university announces the opening of a state-of-the-art artificial intelligence research laboratory",
                imageURL: nil,
                articleURL: "https://university.edu/news/ai-lab",
                publishedDate: Date().addingTimeInterval(-86400)
            ),
            UniversityNews(
                id: UUID().uuidString,
                title: "Registration Period Extended",
                description: "Due to high demand, the elective registration period has been extended by one week",
                imageURL: nil,
                articleURL: "https://university.edu/news/registration",
                publishedDate: Date().addingTimeInterval(-172800)
            ),
            UniversityNews(
                id: UUID().uuidString,
                title: "Student Success Stories",
                description: "Meet the students who won international competitions this semester",
                imageURL: nil,
                articleURL: "https://university.edu/news/success",
                publishedDate: Date().addingTimeInterval(-259200)
            )
        ]
    }
}

// MARK: - Components
struct NewsCard: View {
    let news: UniversityNews
    @State private var showWebView = false
    
    var body: some View {
        Button(action: { showWebView = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Image or placeholder
                if let imageURL = news.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .cornerRadius(12)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 200)
                        
                        Image(systemName: "newspaper")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(news.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(news.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(news.publishedDate, style: .date)
                            .font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showWebView) {
            SafariView(url: URL(string: news.articleURL)!)
        }
    }
}

struct EmptyNewsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No News Available")
                .font(.headline)
            
            Text("Check back later for updates")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Simple Safari View wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

import SafariServices

extension SFSafariViewController {
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}
