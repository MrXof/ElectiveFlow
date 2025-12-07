import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            // Avatar
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(appState.currentUser?.name.prefix(1) ?? "U")
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appState.currentUser?.name ?? "User")
                                    .font(.headline)
                                
                                Text(appState.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                RoleBadge(role: appState.currentUser?.role ?? .student)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Preferences Section
                Section(L10n.shared.text("settings.preferences", language: appState.selectedLanguage)) {
                    Toggle(isOn: $appState.isDarkMode) {
                        Label(L10n.shared.text("settings.dark_mode", language: appState.selectedLanguage), systemImage: "moon.fill")
                    }
                    .onChange(of: appState.isDarkMode) { _ in
                        appState.toggleDarkMode()
                    }
                    
                    Toggle(isOn: $appState.notificationsEnabled) {
                        Label(L10n.shared.text("settings.notifications", language: appState.selectedLanguage), systemImage: "bell.fill")
                    }
                    .onChange(of: appState.notificationsEnabled) { _ in
                        appState.toggleNotifications()
                    }
                    
                    Picker(selection: $appState.selectedLanguage) {
                        Text(L10n.shared.text("language.ukrainian", language: appState.selectedLanguage)).tag("UA")
                        Text(L10n.shared.text("language.english", language: appState.selectedLanguage)).tag("EN")
                    } label: {
                        Label(L10n.shared.text("settings.language", language: appState.selectedLanguage), systemImage: "globe")
                    }
                    .onChange(of: appState.selectedLanguage) { newValue in
                        appState.setLanguage(newValue)
                    }
                }
                
                // Data Section
                Section(L10n.shared.text("settings.data", language: appState.selectedLanguage)) {
                    Button(action: clearCache) {
                        Label(L10n.shared.text("settings.clear_cache", language: appState.selectedLanguage), systemImage: "trash")
                    }
                    
                    Button(action: syncData) {
                        Label(L10n.shared.text("settings.sync_data", language: appState.selectedLanguage), systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                
                // App Info Section
                Section(L10n.shared.text("settings.about", language: appState.selectedLanguage)) {
                    HStack {
                        Text(L10n.shared.text("settings.version", language: appState.selectedLanguage))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label(L10n.shared.text("settings.privacy_policy", language: appState.selectedLanguage), systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: TermsView()) {
                        Label(L10n.shared.text("settings.terms", language: appState.selectedLanguage), systemImage: "doc.text")
                    }
                    
                    if let supportURL = URL(string: "https://electiveflow.app/support") {
                        Link(destination: supportURL) {
                            Label(L10n.shared.text("settings.support", language: appState.selectedLanguage), systemImage: "questionmark.circle")
                        }
                    } else {
                        // Якщо URL некоректний, показуємо неактивний рядок замість крашу
                        HStack {
                            Label(L10n.shared.text("settings.support", language: appState.selectedLanguage), systemImage: "questionmark.circle")
                            Spacer()
                            Text("Invalid URL").foregroundColor(.secondary)
                        }
                    }
                }
                
                // Logout Section
                Section {
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Spacer()
                            Text(L10n.shared.text("settings.logout", language: appState.selectedLanguage))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(L10n.shared.text("settings.title", language: appState.selectedLanguage))
            .alert(L10n.shared.text("settings.logout", language: appState.selectedLanguage), isPresented: $showLogoutAlert) {
                Button(L10n.shared.text("settings.cancel", language: appState.selectedLanguage), role: .cancel) {}
                Button(L10n.shared.text("settings.logout", language: appState.selectedLanguage), role: .destructive) {
                    appState.logout()
                }
            } message: {
                Text(L10n.shared.text("settings.logout_message", language: appState.selectedLanguage))
            }
        }
    }
    
    private func clearCache() {
        // Implement cache clearing
        print("Clearing cache...")
    }
    
    private func syncData() {
        // Implement data sync
        print("Syncing data...")
    }
}

struct RoleBadge: View {
    let role: User.UserRole
    
    var body: some View {
        Text(role.rawValue.capitalized)
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(role == .teacher ? Color.blue : Color.green)
            .cornerRadius(6)
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var selectedInterests: Set<String> = []
    
    let availableInterests = [
        "AI", "Machine Learning", "Data Science", "Programming",
        "Web Development", "Mobile Development", "Design",
        "Business", "Marketing", "Soft Skills"
    ]
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
            
            Section("Interests") {
                FlowLayout(spacing: 8) {
                    ForEach(availableInterests, id: \.self) { interest in
                        CategoryChip(
                            title: interest,
                            isSelected: selectedInterests.contains(interest)
                        ) {
                            if selectedInterests.contains(interest) {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button("Save Changes") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = appState.currentUser {
                name = user.name
                email = user.email
                selectedInterests = Set(user.interests)
            }
        }
    }
    
    private func saveProfile() {
        guard var user = appState.currentUser else { return }
        
        user.name = name
        user.email = email
        user.interests = Array(selectedInterests)
        
        appState.login(user: user)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title.bold())
                
                Text("Last updated: December 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Group {
                    SectionHeader(title: "1. Information We Collect")
                    Text("We collect information that you provide directly to us, including your name, email address, and course preferences.")
                    
                    SectionHeader(title: "2. How We Use Your Information")
                    Text("We use the information we collect to provide, maintain, and improve our services, including to process registrations and send you updates.")
                    
                    SectionHeader(title: "3. Information Sharing")
                    Text("We do not share your personal information with third parties except as described in this policy.")
                    
                    SectionHeader(title: "4. Data Security")
                    Text("We implement appropriate security measures to protect your personal information.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title.bold())
                
                Text("Last updated: December 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Group {
                    SectionHeader(title: "1. Acceptance of Terms")
                    Text("By accessing and using ElectiveFlow, you accept and agree to be bound by these Terms of Service.")
                    
                    SectionHeader(title: "2. User Accounts")
                    Text("You are responsible for maintaining the confidentiality of your account and password.")
                    
                    SectionHeader(title: "3. User Conduct")
                    Text("You agree to use the service only for lawful purposes and in accordance with these Terms.")
                    
                    SectionHeader(title: "4. Modifications")
                    Text("We reserve the right to modify these terms at any time.")
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top, 8)
    }
}
