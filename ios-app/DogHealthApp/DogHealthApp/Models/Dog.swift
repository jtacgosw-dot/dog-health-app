import Foundation

struct Dog: Identifiable, Codable {
    let id: String
    var name: String
    var breed: String
    var age: Int
    var weight: Double?
    var imageUrl: String?
    var healthConcerns: [String]
    var allergies: [String]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, 
         name: String, 
         breed: String, 
         age: Int, 
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
