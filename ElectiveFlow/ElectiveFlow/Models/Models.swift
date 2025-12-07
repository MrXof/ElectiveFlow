import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var role: UserRole
    var interests: [String]
    var photoURL: String?
    
    enum UserRole: String, Codable {
        case teacher = "teacher"
        case student = "student"
    }
}

// MARK: - Elective Model
struct Elective: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var period: String
    var teacherId: String
    var teacherName: String
    var maxStudents: Int
    var currentStudents: Int
    var categories: [String]
    var imageURL: String?
    var distributionModel: DistributionModel
    var registrationStartDate: Date
    var registrationEndDate: Date
    var createdAt: Date
    var numberOfGroups: Int?
    
    enum DistributionModel: String, Codable {
        case uniform = "uniform"
        case priority = "priority"
        case manual = "manual"
    }
    
    var isFull: Bool {
        currentStudents >= maxStudents
    }
    
    var availableSlots: Int {
        maxStudents - currentStudents
    }
    
    var fillPercentage: Double {
        guard maxStudents > 0 else { return 0 }
        return Double(currentStudents) / Double(maxStudents)
    }
}

// MARK: - Student Registration
struct StudentRegistration: Identifiable, Codable {
    let id: String
    var studentId: String
    var studentName: String
    var electiveId: String
    var registrationDate: Date
    var priority: Int?
    var groupNumber: Int?
    var status: RegistrationStatus
    
    enum RegistrationStatus: String, Codable {
        case pending = "pending"
        case confirmed = "confirmed"
        case waitlist = "waitlist"
    }
}

// MARK: - Registration Analytics
struct RegistrationAnalytics: Codable {
    var dailyRegistrations: [DailyRegistration]
    var predictedFinalCount: Int?
    var groupBalance: GroupBalance?
    
    struct DailyRegistration: Identifiable, Codable {
        let id: String
        let date: Date
        let count: Int
    }
    
    struct GroupBalance: Codable {
        var groups: [Group]
        var balanceCoefficient: Double
        
        struct Group: Identifiable, Codable {
            let id: String
            let number: Int
            var studentCount: Int
        }
        
        var minCount: Int {
            groups.map { $0.studentCount }.min() ?? 0
        }
        
        var maxCount: Int {
            groups.map { $0.studentCount }.max() ?? 0
        }
    }
}

// MARK: - University News
struct UniversityNews: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var imageURL: String?
    var articleURL: String
    var publishedDate: Date
}
