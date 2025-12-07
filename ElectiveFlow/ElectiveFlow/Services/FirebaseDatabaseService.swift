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
    
    func deleteElective(id: String) async throws {
        try await db.collection(electivesCollection).document(id).delete()
    }
    
    // MARK: - Student Registrations
    func registerStudent(electiveId: String, student: User, priority: Int?) async throws {
        let registration = StudentRegistration(
            id: UUID().uuidString,
            studentId: student.id,
            studentName: student.name,
            electiveId: electiveId,
            registrationDate: Date(),
            priority: priority,
            groupNumber: nil,
            status: .pending
        )
        
        try db.collection(registrationsCollection).document(registration.id).setData(from: registration)
        
        // Update elective student count
        let electiveRef = db.collection(electivesCollection).document(electiveId)
        try await electiveRef.updateData(["currentStudents": FieldValue.increment(Int64(1))])
        
        // Record analytics
        try await recordDailyRegistration(electiveId: electiveId, date: Date())
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
    
    // MARK: - Analytics
    func fetchAnalytics(for electiveId: String) async throws -> RegistrationAnalytics {
        let document = try await db.collection(analyticsCollection).document(electiveId).getDocument()
        return try document.data(as: RegistrationAnalytics.self)
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
    
    func createUser(_ user: User) async throws {
        try db.collection(usersCollection).document(user.id).setData(from: user)
        print("✅ Firebase: User created successfully - ID: \(user.id), Email: \(user.email)")
    }
    
    func updateUser(_ user: User) async throws {
        try db.collection(usersCollection).document(user.id).setData(from: user)
        print("✅ Firebase: User updated successfully - ID: \(user.id)")
    }
}
