import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var hasSeenOnboarding: Bool
    @Published var isDarkMode: Bool
    @Published var selectedLanguage: String
    @Published var notificationsEnabled: Bool
    
    private var databaseService: DatabaseService {
        return FirebaseDatabaseService.shared
    }
    
    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "UA"
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        
        loadCurrentUser()
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    func setLanguage(_ language: String) {
        selectedLanguage = language
        UserDefaults.standard.set(language, forKey: "selectedLanguage")
    }
    
    func toggleNotifications() {
        notificationsEnabled.toggle()
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
    }
    
    func login(user: User) {
        currentUser = user
        saveCurrentUser(user)
    }
    
    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    private func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }
    
    private func saveCurrentUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }
}
