import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var selectedRole: User.UserRole = .teacher
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 60)
                    
                    // Logo
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .padding(.bottom, 20)
                    
                    Text(L10n.shared.text("login.title", language: appState.selectedLanguage))
                        .font(.largeTitle.bold())
                    
                    // Auth Form
                    VStack(spacing: 20) {
                        if isSignUp {
                            TextField(L10n.shared.text("login.name", language: appState.selectedLanguage), text: $name)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }
                        
                        TextField(L10n.shared.text("login.email", language: appState.selectedLanguage), text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        SecureField(L10n.shared.text("login.password", language: appState.selectedLanguage), text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                        
                        // Role Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.shared.text("login.i_am", language: appState.selectedLanguage))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                RoleButton(
                                    title: L10n.shared.text("login.teacher", language: appState.selectedLanguage),
                                    icon: "person.text.rectangle",
                                    isSelected: selectedRole == .teacher
                                ) {
                                    selectedRole = .teacher
                                }
                                
                                RoleButton(
                                    title: L10n.shared.text("login.student", language: appState.selectedLanguage),
                                    icon: "graduationcap",
                                    isSelected: selectedRole == .student
                                ) {
                                    selectedRole = .student
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        // Submit Button
                        Button(action: handleAuth) {
                            Text(isSignUp 
                                 ? L10n.shared.text("login.sign_up", language: appState.selectedLanguage)
                                 : L10n.shared.text("login.login", language: appState.selectedLanguage))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                        .padding(.top, 10)
                        
                        // Toggle Sign Up / Login
                        Button(action: { withAnimation { isSignUp.toggle() } }) {
                            Text(isSignUp 
                                 ? L10n.shared.text("login.have_account", language: appState.selectedLanguage)
                                 : L10n.shared.text("login.no_account", language: appState.selectedLanguage))
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer(minLength: 60)
                }
            }
            .navigationBarHidden(true)
            .alert(L10n.shared.text("login.error", language: appState.selectedLanguage), isPresented: $showAlert) {
                Button(L10n.shared.text("login.ok", language: appState.selectedLanguage)) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleAuth() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = L10n.shared.text("login.fill_fields", language: appState.selectedLanguage)
            showAlert = true
            return
        }
        
        if isSignUp && name.isEmpty {
            alertMessage = L10n.shared.text("login.enter_name", language: appState.selectedLanguage)
            showAlert = true
            return
        }
        
        Task {
            do {
                // Створюємо користувача
                let user = User(
                    id: UUID().uuidString,
                    name: isSignUp ? name : "Demo User",
                    email: email,
                    role: selectedRole,
                    interests: [],
                    photoURL: nil
                )
                
                // Якщо це реєстрація - зберігаємо в Firebase
                if isSignUp {
                    try await FirebaseDatabaseService.shared.createUser(user)
                    print("✅ User saved to Firebase: \(user.email)")
                }
                
                // Логінимо користувача в застосунку
                await MainActor.run {
                    appState.login(user: user)
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
                print("❌ Error saving user to Firebase: \(error)")
            }
        }
    }
}

struct RoleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}
