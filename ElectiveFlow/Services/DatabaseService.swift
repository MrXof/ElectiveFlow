import Foundation

protocol DatabaseService {
    // Electives
    func fetchElectives() async throws -> [Elective]
    func fetchElective(id: String) async throws -> Elective
    func createElective(_ elective: Elective) async throws
    func updateElective(_ elective: Elective) async throws
    func updateElectiveTeacher(electiveId: String, teacherId: String, teacherName: String) async throws
    func deleteElective(id: String) async throws
    
    // Student Registrations
    func registerStudent(electiveId: String, student: User, priority: Int?) async throws
    func fetchRegistrations(for electiveId: String) async throws -> [StudentRegistration]
    func fetchStudentRegistrations(studentId: String) async throws -> [StudentRegistration]
    func updateRegistration(_ registration: StudentRegistration) async throws
    
    // Analytics
    func fetchAnalytics(for electiveId: String) async throws -> RegistrationAnalytics
    func fetchDailyRegistrations(for electiveId: String, days: Int) async throws -> [RegistrationAnalytics.DailyRegistration]
    func recordDailyRegistration(electiveId: String, date: Date) async throws
    
    #if DEBUG
    func generateTestDailyRegistrations(electiveId: String) async throws
    #endif
    
    // News
    func fetchUniversityNews() async throws -> [UniversityNews]
    
    // Users
    func fetchUser(id: String) async throws -> User
    func fetchUserByEmail(_ email: String) async throws -> [User]
    func createUser(_ user: User) async throws
    func updateUser(_ user: User) async throws
}
