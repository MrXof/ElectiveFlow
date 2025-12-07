import SwiftUI

struct CreateElectiveView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ElectivesViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedPeriod = "Fall 2025"
    @State private var maxStudents = 50
    @State private var selectedCategories: Set<String> = []
    @State private var numberOfGroups = 2
    @State private var distributionModel: Elective.DistributionModel = .uniform
    @State private var registrationStart = Date()
    @State private var registrationEnd = Date().addingTimeInterval(86400 * 30)
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let availableCategories = ["STEM", "AI", "Data Science", "Soft Skills", "Business", "Design", "Programming"]
    let periods = ["Fall 2025", "Spring 2026", "Summer 2026"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Elective Name", text: $name)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(periods, id: \.self) { period in
                            Text(period).tag(period)
                        }
                    }
                }
                
                Section("Capacity") {
                    Stepper("Max Students: \(maxStudents)", value: $maxStudents, in: 10...200, step: 10)
                    
                    Stepper("Number of Groups: \(numberOfGroups)", value: $numberOfGroups, in: 1...10)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(availableCategories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategories.contains(category),
                                action: {
                                    toggleCategory(category)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Text("Categories")
                        if !selectedCategories.isEmpty {
                            Text("(\(selectedCategories.count) selected)")
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    if selectedCategories.isEmpty {
                        Text("Select at least one category")
                            .foregroundColor(.red)
                    }
                }
                
                Section("Distribution Model") {
                    Picker("Model", selection: $distributionModel) {
                        Text("Uniform").tag(Elective.DistributionModel.uniform)
                        Text("Priority-Based").tag(Elective.DistributionModel.priority)
                        Text("Manual").tag(Elective.DistributionModel.manual)
                    }
                    .pickerStyle(.segmented)
                    
                    Text(distributionModelDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Registration Period") {
                    DatePicker("Start Date", selection: $registrationStart, displayedComponents: .date)
                    DatePicker("End Date", selection: $registrationEnd, displayedComponents: .date)
                }
            }
            .navigationTitle("Create Elective")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createElective()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !description.isEmpty && !selectedCategories.isEmpty
    }
    
    private var distributionModelDescription: String {
        switch distributionModel {
        case .uniform:
            return "Students are distributed evenly across all groups"
        case .priority:
            return "Students are assigned based on their priority preferences"
        case .manual:
            return "You will manually assign students to groups"
        }
    }
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
            print("🔴 Removed category: \(category)")
        } else {
            selectedCategories.insert(category)
            print("🟢 Added category: \(category)")
        }
        print("📋 Selected categories: \(selectedCategories.sorted())")
    }
    
    private func createElective() {
        guard isValid else {
            alertMessage = "Please fill in all required fields"
            showAlert = true
            return
        }
        
        guard let currentUser = appState.currentUser else {
            alertMessage = "User not found"
            showAlert = true
            return
        }
        
        let elective = Elective(
            id: UUID().uuidString,
            name: name,
            description: description,
            period: selectedPeriod,
            teacherId: currentUser.id,
            teacherName: currentUser.name,
            maxStudents: maxStudents,
            currentStudents: 0,
            categories: Array(selectedCategories),
            imageURL: nil,
            distributionModel: distributionModel,
            registrationStartDate: registrationStart,
            registrationEndDate: registrationEnd,
            createdAt: Date(),
            numberOfGroups: numberOfGroups
        )
        
        print("📝 Creating elective: \(elective.name)")
        print("   ID: \(elective.id)")
        print("   Teacher ID: \(elective.teacherId)")
        print("   Teacher Name: \(elective.teacherName)")
        print("   Period: \(elective.period)")
        print("   Categories: \(elective.categories)")
        
        Task {
            do {
                await viewModel.createElective(elective)
                print("✅ Elective created successfully!")
                dismiss()
            } catch {
                print("❌ Error creating elective: \(error)")
                alertMessage = "Failed to create elective: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundColor(isSelected ? .blue : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }
    }
}

// Simple Flow Layout for categories
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, row) in result.rows.enumerated() {
            let rowY = bounds.minY + row.yOffset
            for (subviewIndex, subview) in row.subviews.enumerated() {
                let subviewSize = subview.sizeThatFits(.unspecified)
                let x = bounds.minX + row.xOffsets[subviewIndex]
                subview.place(at: CGPoint(x: x, y: rowY), proposal: ProposedViewSize(subviewSize))
            }
        }
    }
    
    struct FlowResult {
        var rows: [(subviews: [LayoutSubview], xOffsets: [CGFloat], yOffset: CGFloat)] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentRow: (subviews: [LayoutSubview], xOffsets: [CGFloat], width: CGFloat) = ([], [], 0)
            var yOffset: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentRow.width + size.width + (currentRow.subviews.isEmpty ? 0 : spacing) <= maxWidth {
                    currentRow.subviews.append(subview)
                    currentRow.xOffsets.append(currentRow.width)
                    currentRow.width += size.width + (currentRow.subviews.isEmpty ? 0 : spacing)
                } else {
                    if !currentRow.subviews.isEmpty {
                        rows.append((currentRow.subviews, currentRow.xOffsets, yOffset))
                        yOffset += size.height + spacing
                    }
                    currentRow = ([subview], [0], size.width)
                }
            }
            
            if !currentRow.subviews.isEmpty {
                rows.append((currentRow.subviews, currentRow.xOffsets, yOffset))
                yOffset += currentRow.subviews.first?.sizeThatFits(.unspecified).height ?? 0
            }
            
            self.size = CGSize(width: maxWidth, height: yOffset)
        }
    }
}
