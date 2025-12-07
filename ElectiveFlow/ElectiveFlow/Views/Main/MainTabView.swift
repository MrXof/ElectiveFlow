import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(L10n.shared.text("tab.home", language: appState.selectedLanguage), systemImage: "house.fill")
                }
            
            if appState.currentUser?.role == .teacher {
                ElectivesListView()
                    .tabItem {
                        Label(L10n.shared.text("tab.electives", language: appState.selectedLanguage), systemImage: "books.vertical.fill")
                    }
            } else {
                StudentElectivesView()
                    .tabItem {
                        Label(L10n.shared.text("tab.catalog", language: appState.selectedLanguage), systemImage: "book.fill")
                    }
            }
            
            NewsView()
                .tabItem {
                    Label(L10n.shared.text("tab.news", language: appState.selectedLanguage), systemImage: "newspaper.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label(L10n.shared.text("tab.settings", language: appState.selectedLanguage), systemImage: "gear")
                }
        }
        .accentColor(.blue)
    }
}
