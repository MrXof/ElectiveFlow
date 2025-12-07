import SwiftUI
import FirebaseCore

@main
struct ElectiveFlowApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        // Перевірка, чи не сконфігуровано вже
        if FirebaseApp.app() != nil {
            print("Firebase already configured. Skipping duplicate configure() call.")
            return
        }
        
        // Спочатку пробуємо завантажити GoogleService-Info.plist
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
            print("✅ Firebase configured with GoogleService-Info.plist")
            return
        }
        
        // Якщо файлу немає, використовуємо mock конфігурацію для розробки
        print("⚠️ GoogleService-Info.plist not found. Using mock Firebase configuration for development.")
        
        let options = FirebaseOptions(googleAppID: "1:123456789:ios:abcdef123456", gcmSenderID: "123456789")
        options.projectID = "elective-flow-demo"
        options.apiKey = "AIzaSyDemoKeyForDevelopment123456789"
        options.bundleID = Bundle.main.bundleIdentifier ?? "com.demo.ElectiveFlow"
        options.clientID = "123456789-abcdefghijklmnop.apps.googleusercontent.com"
        options.databaseURL = "https://elective-flow-demo.firebaseio.com"
        options.storageBucket = "elective-flow-demo.appspot.com"
        
        FirebaseApp.configure(options: options)
        print("✅ Firebase configured with mock options for development")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
