import Foundation

class GroupDistributionAlgorithm {
    
    // MARK: - Optimal Distribution
    static func optimizeDistribution(
        registrations: [StudentRegistration],
        numberOfGroups: Int,
        maxStudentsPerGroup: Int
    ) -> ([StudentRegistration], Double) {
        
        var updatedRegistrations = registrations
        var groups: [[StudentRegistration]] = Array(repeating: [], count: numberOfGroups)
        
        // Sort by priority (if exists), then by registration date
        let sortedRegistrations = registrations.sorted { reg1, reg2 in
            if let p1 = reg1.priority, let p2 = reg2.priority {
                return p1 < p2
            }
            return reg1.registrationDate < reg2.registrationDate
        }
        
        // Greedy distribution with balance
        for registration in sortedRegistrations {
            // Find group with minimum students
            if let minGroupIndex = groups.enumerated()
                .min(by: { $0.element.count < $1.element.count })?
                .offset {
                
                if groups[minGroupIndex].count < maxStudentsPerGroup {
                    var updatedReg = registration
                    updatedReg.groupNumber = minGroupIndex + 1
                    updatedReg.status = .confirmed
                    groups[minGroupIndex].append(updatedReg)
                    
                    if let index = updatedRegistrations.firstIndex(where: { $0.id == registration.id }) {
                        updatedRegistrations[index] = updatedReg
                    }
                }
            }
        }
        
        // Calculate balance coefficient
        let counts = groups.map { $0.count }
        let maxCount = counts.max() ?? 0
        let minCount = counts.min() ?? 0
        let balanceCoefficient = Double(maxCount - minCount)
        
        return (updatedRegistrations, balanceCoefficient)
    }
    
    // MARK: - Linear Regression for Prediction
    static func predictFinalCount(dailyData: [RegistrationAnalytics.DailyRegistration]) -> Int? {
        guard dailyData.count >= 2 else { return nil }
        
        let sorted = dailyData.sorted { $0.date < $1.date }
        let n = Double(sorted.count)
        
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        
        for (index, data) in sorted.enumerated() {
            let x = Double(index)
            let y = Double(data.count)
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }
        
        // Calculate slope (a) and intercept (b) for y = ax + b
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }
        
        let a = (n * sumXY - sumX * sumY) / denominator
        let b = (sumY - a * sumX) / n
        
        // Predict for total period (e.g., 14 days)
        let totalDays = 14.0
        let predicted = a * totalDays + b
        
        return max(Int(predicted.rounded()), sorted.last?.count ?? 0)
    }
    
    // MARK: - Cosine Similarity for Recommendations
    static func cosineSimilarity(
        studentInterests: [String],
        electiveCategories: [String]
    ) -> Double {
        let allCategories = Set(studentInterests + electiveCategories)
        
        var vectorA: [Double] = []
        var vectorB: [Double] = []
        
        for category in allCategories {
            vectorA.append(studentInterests.contains(category) ? 1.0 : 0.0)
            vectorB.append(electiveCategories.contains(category) ? 1.0 : 0.0)
        }
        
        let dotProduct = zip(vectorA, vectorB).map(*).reduce(0, +)
        let magnitudeA = sqrt(vectorA.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(vectorB.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    static func recommendElectives(
        for student: User,
        from electives: [Elective]
    ) -> [Elective] {
        let recommendations = electives.map { elective -> (Elective, Double) in
            let similarity = cosineSimilarity(
                studentInterests: student.interests,
                electiveCategories: elective.categories
            )
            return (elective, similarity)
        }
        
        return recommendations
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
}
