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
    @State private var isLoading = false
    
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
                                .disabled(isLoading)
                        }
                        
                        TextField(L10n.shared.text("login.email", language: appState.selectedLanguage), text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .disabled(isLoading)
                        
                        SecureField(L10n.shared.text("login.password", language: appState.selectedLanguage), text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .disabled(isLoading)
                        
                        // Password Requirements (only show during sign up)
                        if isSignUp && !password.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ValidationRow(
                                    text: "At least 6 characters",
                                    isValid: password.count >= 6
                                )
                                ValidationRow(
                                    text: "Contains at least one letter",
                                    isValid: password.contains(where: { $0.isLetter })
                                )
                            }
                            .font(.caption)
                            .padding(.horizontal, 4)
                        }
                        
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
                        .disabled(isLoading)
                        
                        // Submit Button
                        Button(action: handleAuth) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp 
                                     ? L10n.shared.text("login.sign_up", language: appState.selectedLanguage)
                                     : L10n.shared.text("login.login", language: appState.selectedLanguage))
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isLoading ? Color.blue.opacity(0.6) : Color.blue)
                        .cornerRadius(16)
                        .disabled(isLoading)
                        .padding(.top, 10)
                        
                        // Toggle Sign Up / Login
                        Button(action: { 
                            withAnimation { 
                                isSignUp.toggle()
                                // Clear fields when switching
                                name = ""
                                alertMessage = ""
                            }
                        }) {
                            Text(isSignUp 
                                 ? L10n.shared.text("login.have_account", language: appState.selectedLanguage)
                                 : L10n.shared.text("login.no_account", language: appState.selectedLanguage))
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoading)
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
        // Validate email
        guard isValidEmail(email) else {
            alertMessage = "Please enter a valid email address (e.g., user@example.com)"
            showAlert = true
            return
        }
        
        // Validate password
        guard isValidPassword(password) else {
            alertMessage = "Password must be at least 6 characters and contain at least one letter"
            showAlert = true
            return
        }
        
        // Validate name for sign up
        if isSignUp {
            guard !name.isEmpty, name.count >= 2 else {
                alertMessage = "Please enter your full name (at least 2 characters)"
                showAlert = true
                return
            }
        }
        
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    // РЕЄСТРАЦІЯ
                    print("📝 Signing up new user...")
                    print("   Email: \(email)")
                    print("   Role: \(selectedRole.rawValue)")
                    
                    // Перевірити, чи email вже існує
                    let existingUsers = try await FirebaseDatabaseService.shared.fetchUserByEmail(email)
                    
                    if !existingUsers.isEmpty {
                        throw NSError(
                            domain: "ElectiveFlow",
                            code: 409,
                            userInfo: [NSLocalizedDescriptionKey: "An account with this email already exists. Please login instead."]
                        )
                    }
                    
                    // Створити нового користувача
                    let newUser = User(
                        id: UUID().uuidString,
                        name: name,
                        email: email.lowercased().trimmingCharacters(in: .whitespaces),
                        role: selectedRole,
                        interests: [],
                        photoURL: nil
                    )
                    
                    // Зберегти в Firebase
                    try await FirebaseDatabaseService.shared.createUser(newUser)
                    print("✅ User registered successfully: \(newUser.email) (ID: \(newUser.id))")
                    
                    // Автоматичний вхід після реєстрації
                    await MainActor.run {
                        appState.login(user: newUser)
                        isLoading = false
                    }
                    
                } else {
                    // ВХІД
                    print("🔍 Logging in user with email: \(email)")
                    
                    // Знайти користувача по email
                    let users = try await FirebaseDatabaseService.shared.fetchUserByEmail(
                        email.lowercased().trimmingCharacters(in: .whitespaces)
                    )
                    
                    guard let existingUser = users.first else {
                        throw NSError(
                            domain: "ElectiveFlow",
                            code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "No account found with this email. Please sign up first."]
                        )
                    }
                    
                    print("✅ User found: \(existingUser.name) (ID: \(existingUser.id))")
                    
                    // Перевірка ролі (опціонально)
                    if existingUser.role != selectedRole {
                        print("⚠️ Warning: User role mismatch. Account role: \(existingUser.role.rawValue), Selected: \(selectedRole.rawValue)")
                    }
                    
                    // Вхід з існуючим користувачем
                    await MainActor.run {
                        appState.login(user: existingUser)
                        isLoading = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
                print("❌ Authentication error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Validation Functions
    
    private func isValidEmail(_ email: String) -> Bool {
        // Email должен содержать @ и домен
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Минимум 6 символов и хотя бы одна буква
        let hasMinimumLength = password.count >= 6
        let hasLetter = password.contains(where: { $0.isLetter })
        return hasMinimumLength && hasLetter
    }
}

// MARK: - Validation Row
struct ValidationRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary)
            
            Text(text)
                .foregroundColor(isValid ? .green : .secondary)
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
