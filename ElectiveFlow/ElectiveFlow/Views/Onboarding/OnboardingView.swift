import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var pages: [OnboardingPage] {
        let lang = appState.selectedLanguage
        return [
            OnboardingPage(
                title: L10n.shared.text("onboarding.welcome.title", language: lang),
                description: L10n.shared.text("onboarding.welcome.description", language: lang),
                systemImage: "rectangle.stack.fill"
            ),
            OnboardingPage(
                title: L10n.shared.text("onboarding.teachers.title", language: lang),
                description: L10n.shared.text("onboarding.teachers.description", language: lang),
                systemImage: "person.text.rectangle"
            ),
            OnboardingPage(
                title: L10n.shared.text("onboarding.analytics.title", language: lang),
                description: L10n.shared.text("onboarding.analytics.description", language: lang),
                systemImage: "chart.line.uptrend.xyaxis"
            ),
            OnboardingPage(
                title: L10n.shared.text("onboarding.students.title", language: lang),
                description: L10n.shared.text("onboarding.students.description", language: lang),
                systemImage: "book.fill"
            )
        ]
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 30) {
                            Group {
                                if #available(iOS 17.0, *) {
                                    Image(systemName: page.systemImage)
                                        .font(.system(size: 100))
                                        .foregroundStyle(.blue.gradient)
                                        .symbolEffect(.bounce, value: currentPage == index)
                                } else {
                                    Image(systemName: page.systemImage)
                                        .font(.system(size: 100))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            VStack(spacing: 16) {
                                Text(page.title)
                                    .font(.largeTitle.bold())
                                    .multilineTextAlignment(.center)
                                
                                Text(page.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 450)
                
                Spacer()
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation {
                            appState.completeOnboarding()
                        }
                    }
                }) {
                    Text(currentPage < pages.count - 1 
                         ? L10n.shared.text("onboarding.next", language: appState.selectedLanguage)
                         : L10n.shared.text("onboarding.get_started", language: appState.selectedLanguage))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let systemImage: String
}
