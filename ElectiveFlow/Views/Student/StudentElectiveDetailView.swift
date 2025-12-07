import SwiftUI

struct StudentElectiveDetailView: View {
    let elective: Elective
    @StateObject private var viewModel: StudentElectiveDetailViewModel
    @State private var showRegistrationSheet = false
    @State private var showSuccessAlert = false
    
    init(elective: Elective) {
        self.elective = elective
        _viewModel = StateObject(wrappedValue: StudentElectiveDetailViewModel(elective: elective))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image or Placeholder
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 200)
                    
                    VStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(elective.name)
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .cornerRadius(20)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "person.circle", title: "Instructor", value: elective.teacherName)
                        InfoRow(icon: "calendar", title: "Period", value: elective.period)
                        InfoRow(icon: "person.2", title: "Capacity", value: "\(elective.currentStudents) / \(elective.maxStudents)")
                        
                        // Availability Bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Availability")
                                    .font(.subheadline.weight(.medium))
                                
                                Spacer()
                                
                                Text("\(elective.availableSlots) spots left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(elective.isFull ? Color.red : Color.green)
                                        .frame(width: geometry.size.width * elective.fillPercentage, height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this course")
                            .font(.headline)
                        
                        Text(elective.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(elective.categories, id: \.self) { category in
                                CategoryBadge(category: category)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Registration Period
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Registration Period")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Starts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(elective.registrationStartDate, style: .date)
                                    .font(.subheadline.weight(.medium))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Ends")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(elective.registrationEndDate, style: .date)
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Registration Status
                    if let registration = viewModel.currentRegistration {
                        RegistrationStatusCard(registration: registration)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if viewModel.currentRegistration == nil {
                Button(action: { showRegistrationSheet = true }) {
                    HStack {
                        Image(systemName: elective.isFull ? "exclamationmark.circle" : "checkmark.circle")
                        Text(elective.isFull ? "Join Waitlist" : "Join Elective")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(elective.isFull ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: $showRegistrationSheet) {
            RegisterForElectiveView(
                elective: elective,
                onSuccess: {
                    showSuccessAlert = true
                    Task {
                        await viewModel.checkRegistration()
                    }
                }
            )
        }
        .alert("Registration Successful!", isPresented: $showSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("You have successfully registered for \(elective.name)")
        }
        .task {
            await viewModel.checkRegistration()
        }
    }
}

// MARK: - View Model
@MainActor
class StudentElectiveDetailViewModel: ObservableObject {
    @Published var currentRegistration: StudentRegistration?
    
    private let elective: Elective
    private let databaseService: DatabaseService = FirebaseDatabaseService.shared
    
    init(elective: Elective) {
        self.elective = elective
    }
    
    func checkRegistration() async {
        // Check if current user is already registered
        // Mock implementation
        do {
            let registrations = try await databaseService.fetchRegistrations(for: elective.id)
            currentRegistration = registrations.first // In real app, filter by current user
        } catch {
            print("Error checking registration: \(error)")
        }
    }
}

// MARK: - Components
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }
            
            Spacer()
        }
    }
}

struct CategoryBadge: View {
    let category: String
    
    var body: some View {
        Text(category)
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
    }
}

struct RegistrationStatusCard: View {
    let registration: StudentRegistration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Registration")
                    .font(.headline)
                
                Spacer()
                
                StatusBadge(status: registration.status)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Registered on")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(registration.registrationDate, style: .date)
                        .font(.subheadline.weight(.medium))
                }
                
                if let groupNumber = registration.groupNumber {
                    HStack {
                        Text("Assigned Group")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Group \(groupNumber)")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RegisterForElectiveView: View {
    @Environment(\.dismiss) var dismiss
    let elective: Elective
    let onSuccess: () -> Void
    
    @State private var priority: Int = 1
    @State private var notes: String = ""
    @State private var isRegistering = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Elective Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(elective.name)
                            .font(.headline)
                        Text(elective.period)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if elective.distributionModel == .priority {
                    Section("Priority") {
                        Picker("Your Priority", selection: $priority) {
                            Text("1st Choice").tag(1)
                            Text("2nd Choice").tag(2)
                            Text("3rd Choice").tag(3)
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Select your preference level for this elective")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: registerForElective) {
                        if isRegistering {
                            HStack {
                                ProgressView()
                                Text("Registering...")
                            }
                        } else {
                            Text("Confirm Registration")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isRegistering)
                }
            }
            .navigationTitle("Join Elective")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func registerForElective() {
        isRegistering = true
        
        Task {
            // Simulate registration delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            // In real app, call database service here
            
            await MainActor.run {
                isRegistering = false
                onSuccess()
                dismiss()
            }
        }
    }
}
