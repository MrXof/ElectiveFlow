import SwiftUI

struct CreateElectiveView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ElectivesViewModel
    
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
                
                Section("Categories") {
                    FlowLayout(spacing: 8) {
                        ForEach(availableCategories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategories.contains(category)
                            ) {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
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
    
    private func createElective() {
        guard isValid else {
            alertMessage = "Please fill in all required fields"
            showAlert = true
            return
        }
        
        let elective = Elective(
            id: UUID().uuidString,
            name: name,
            description: description,
            period: selectedPeriod,
            teacherId: "current-teacher-id", // Replace with actual teacher ID
            teacherName: "Current Teacher", // Replace with actual teacher name
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
        
        Task {
            await viewModel.createElective(elective)
            dismiss()
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(16)
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
