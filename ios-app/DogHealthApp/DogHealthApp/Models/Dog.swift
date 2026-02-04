import Foundation

struct Dog: Identifiable, Codable {
    let id: String
    var name: String
    var breed: String
    var age: Double // Changed from Int to support fractional ages (e.g., 0.5 for 6 months)
    var weight: Double?
    var imageUrl: String?
    var healthConcerns: [String]
    var allergies: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, 
         name: String, 
         breed: String, 
         age: Double, 
         weight: Double? = nil,
         imageUrl: String? = nil,
         healthConcerns: [String] = [],
         allergies: [String] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.breed = breed
        self.age = age
        self.weight = weight
        self.imageUrl = imageUrl
        self.healthConcerns = healthConcerns
        self.allergies = allergies
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed property for display-friendly age string
    var ageDisplayString: String {
        if age < 1 {
            let months = Int(age * 12)
            return months == 1 ? "1 month" : "\(months) months"
        } else if age == floor(age) {
            let years = Int(age)
            return years == 1 ? "1 year" : "\(years) years"
        } else {
            let years = Int(age)
            let months = Int((age - Double(years)) * 12)
            if months == 0 {
                return years == 1 ? "1 year" : "\(years) years"
            }
            let yearStr = years == 1 ? "1 year" : "\(years) years"
            let monthStr = months == 1 ? "1 month" : "\(months) months"
            return "\(yearStr), \(monthStr)"
        }
    }
}

struct DogProfile: Codable {
    let dog: Dog
    var customDiet: String?
    var foodRecommendations: [FoodRecommendation]
    var treats: [String]
    
    init(dog: Dog, customDiet: String? = nil, foodRecommendations: [FoodRecommendation] = [], treats: [String] = []) {
        self.dog = dog
        self.customDiet = customDiet
        self.foodRecommendations = foodRecommendations
        self.treats = treats
    }
}

struct FoodRecommendation: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String
    let category: String
    
    init(id: String = UUID().uuidString, name: String, brand: String, category: String) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
    }
}
