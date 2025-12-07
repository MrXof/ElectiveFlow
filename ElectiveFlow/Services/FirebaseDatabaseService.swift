import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseDatabaseService: DatabaseService {
    static let shared = FirebaseDatabaseService()
    
    private var db: Firestore {
        return Firestore.firestore()
    }
    private let electivesCollection = "electives"
    private let registrationsCollection = "registrations"
    private let analyticsCollection = "analytics"
    private let newsCollection = "news"
    private let usersCollection = "users"
    
    private init() {}
    
    // MARK: - Electives
    func fetchElectives() async throws -> [Elective] {
        let snapshot = try await db.collection(electivesCollection).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Elective.self) }
    }
    
    func fetchElective(id: String) async throws -> Elective {
        let document = try await db.collection(electivesCollection).document(id).getDocument()
        guard let elective = try? document.data(as: Elective.self) else {
            throw NSError(domain: "ElectiveFlow", code: 404, userInfo: [NSLocalizedDescriptionKey: "Elective not found"])
        }
        return elective
    }
    
    func createElective(_ elective: Elective) async throws {
        try db.collection(electivesCollection).document(elective.id).setData(from: elective)
    }
    
    func updateElective(_ elective: Elective) async throws {
        try db.collection(electivesCollection).document(elective.id).setData(from: elective)
    }
    
    func updateElectiveTeacher(electiveId: String, teacherId: String, teacherName: String) async throws {
        try await db.collection(electivesCollection).document(electiveId).updateData([
            "teacherId": teacherId,
            "teacherName": teacherName
        ])
        print("✅ Firebase: Elective teacher updated - ID: \(electiveId)")
    }
    
    func deleteElective(id: String) async throws {
        // Delete all student registrations for this elective
        let registrationsSnapshot = try await db.collection(registrationsCollection)
            .whereField("electiveId", isEqualTo: id)
            .getDocuments()
        
        for document in registrationsSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete analytics data
        let analyticsRef = db.collection(analyticsCollection).document(id)
        
        // Delete daily registrations subcollection
        let dailySnapshot = try await analyticsRef.collection("daily").getDocuments()
        for document in dailySnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete analytics document
        try await analyticsRef.delete()
        
        // Finally, delete the elective itself
        try await db.collection(electivesCollection).document(id).delete()
        
        print("✅ Firebase: Elective deleted successfully - ID: \(id)")
    }
    
    // MARK: - Student Registrations
    func registerStudent(electiveId: String, student: User, priority: Int?) async throws {
        print("📝 Registering student in Firebase...")
        print("   Student: \(student.name) (ID: \(student.id))")
        print("   Elective ID: \(electiveId)")
        print("   Priority: \(priority ?? 0)")
        
        // Check if student is already registered
        let existingRegistrations = try await fetchRegistrations(for: electiveId)
        if existingRegistrations.contains(where: { $0.studentId == student.id }) {
            print("⚠️ Student already registered for this elective")
            throw NSError(domain: "ElectiveFlow", code: 409, userInfo: [NSLocalizedDescriptionKey: "You are already registered for this elective"])
        }
        
        // Fetch elective to check for groups
        let elective = try await fetchElective(id: electiveId)
        
        // Determine group assignment if elective has groups
        var assignedGroupNumber: Int? = nil
        var registrationStatus: StudentRegistration.RegistrationStatus = .pending
        
        if let numberOfGroups = elective.numberOfGroups, numberOfGroups > 0 {
            // Auto-assign to the group with fewest students
            let groupCounts = calculateGroupCounts(from: existingRegistrations, numberOfGroups: numberOfGroups)
            if let minGroup = groupCounts.min(by: { $0.value < $1.value })?.key {
                assignedGroupNumber = minGroup
                registrationStatus = .confirmed
                print("✅ Auto-assigned to group \(minGroup)")
            }
        }
        
        let registration = StudentRegistration(
            id: UUID().uuidString,
            studentId: student.id,
            studentName: student.name,
            electiveId: electiveId,
            registrationDate: Date(),
            priority: priority,
            groupNumber: assignedGroupNumber,
            status: registrationStatus
        )
        
        // Save registration
        try await db.collection(registrationsCollection).document(registration.id).setData(from: registration)
        print("✅ Registration document created: \(registration.id)")
        
        // Update elective student count
        let electiveRef = db.collection(electivesCollection).document(electiveId)
        try await electiveRef.updateData(["currentStudents": FieldValue.increment(Int64(1))])
        print("✅ Elective currentStudents incremented")
        
        // Record analytics
        try await recordDailyRegistration(electiveId: electiveId, date: Date())
        print("✅ Daily registration recorded")
        
        print("🎉 Student registration complete!")
    }
    
    // Helper function to calculate current students per group
    private func calculateGroupCounts(from registrations: [StudentRegistration], numberOfGroups: Int) -> [Int: Int] {
        var counts: [Int: Int] = [:]
        
        // Initialize all groups with 0
        for groupNum in 1...numberOfGroups {
            counts[groupNum] = 0
        }
        
        // Count students in each group
        for registration in registrations {
            if let groupNum = registration.groupNumber {
                counts[groupNum, default: 0] += 1
            }
        }
        
        return counts
    }
    
    func fetchRegistrations(for electiveId: String) async throws -> [StudentRegistration] {
        let snapshot = try await db.collection(registrationsCollection)
            .whereField("electiveId", isEqualTo: electiveId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: StudentRegistration.self) }
    }
    
    func fetchStudentRegistrations(studentId: String) async throws -> [StudentRegistration] {
        let snapshot = try await db.collection(registrationsCollection)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: StudentRegistration.self) }
    }
    
    func updateRegistration(_ registration: StudentRegistration) async throws {
        try db.collection(registrationsCollection).document(registration.id).setData(from: registration)
    }
    
    // Auto-distribute students without groups
    func autoDistributeUnassignedStudents(electiveId: String) async throws {
        print("🔄 Auto-distributing unassigned students...")
        
        // Fetch elective
        let elective = try await fetchElective(id: electiveId)
        
        guard let numberOfGroups = elective.numberOfGroups, numberOfGroups > 0 else {
            print("⚠️ Elective has no groups configured")
            return
        }
        
        // Fetch all registrations
        let registrations = try await fetchRegistrations(for: electiveId)
        
        // Find unassigned students
        let unassigned = registrations.filter { $0.groupNumber == nil }
        
        guard !unassigned.isEmpty else {
            print("✅ No unassigned students found")
            return
        }
        
        print("📋 Found \(unassigned.count) unassigned students")
        
        // Calculate current group counts
        var groupCounts = calculateGroupCounts(from: registrations.filter { $0.groupNumber != nil }, numberOfGroups: numberOfGroups)
        
        // Assign each unassigned student to the group with fewest students
        for registration in unassigned {
            if let minGroup = groupCounts.min(by: { $0.value < $1.value })?.key {
                var updatedReg = registration
                updatedReg.groupNumber = minGroup
                updatedReg.status = .confirmed
                
                try await updateRegistration(updatedReg)
                groupCounts[minGroup, default: 0] += 1
                
                print("   ✅ \(registration.studentName) → Group \(minGroup)")
            }
        }
        
        print("🎉 Auto-distribution complete!")
    }
    
    // MARK: - Analytics
    func fetchAnalytics(for electiveId: String) async throws -> RegistrationAnalytics {
        let document = try await db.collection(analyticsCollection).document(electiveId).getDocument()
        return try document.data(as: RegistrationAnalytics.self)
    }
    
    func fetchDailyRegistrations(for electiveId: String, days: Int = 30) async throws -> [RegistrationAnalytics.DailyRegistration] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let analyticsRef = db.collection(analyticsCollection).document(electiveId)
        let snapshot = try await analyticsRef.collection("daily")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            guard let timestamp = doc.data()["date"] as? Timestamp,
                  let count = doc.data()["count"] as? Int else {
                return nil
            }
            
            return RegistrationAnalytics.DailyRegistration(
                id: doc.documentID,
                date: timestamp.dateValue(),
                count: count
            )
        }
    }
    
    func recordDailyRegistration(electiveId: String, date: Date) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateString = ISO8601DateFormatter().string(from: startOfDay)
        
        let analyticsRef = db.collection(analyticsCollection).document(electiveId)
        let dailyRegRef = analyticsRef.collection("daily").document(dateString)
        
        try await dailyRegRef.setData([
            "date": Timestamp(date: startOfDay),
            "count": FieldValue.increment(Int64(1))
        ], merge: true)
    }
    
    // MARK: - News
    func fetchUniversityNews() async throws -> [UniversityNews] {
        let snapshot = try await db.collection(newsCollection)
            .order(by: "publishedDate", descending: true)
            .limit(to: 20)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: UniversityNews.self) }
    }
    
    // MARK: - Users
    func fetchUser(id: String) async throws -> User {
        let document = try await db.collection(usersCollection).document(id).getDocument()
        guard let user = try? document.data(as: User.self) else {
            throw NSError(domain: "ElectiveFlow", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return user
    }
    
    func fetchUserByEmail(_ email: String) async throws -> [User] {
        let snapshot = try await db.collection(usersCollection)
            .whereField("email", isEqualTo: email.lowercased().trimmingCharacters(in: .whitespaces))
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
    
    func createUser(_ user: User) async throws {
        try await db.collection(usersCollection).document(user.id).setData(from: user)
        print("✅ Firebase: User created successfully")
        print("   ID: \(user.id)")
        print("   Name: \(user.name)")
        print("   Email: \(user.email)")
        print("   Role: \(user.role.rawValue)")
    }
    
    func updateUser(_ user: User) async throws {
        try await db.collection(usersCollection).document(user.id).setData(from: user)
        print("✅ Firebase: User updated successfully - ID: \(user.id)")
    }
}
