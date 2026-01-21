import Foundation

struct Recipe: Identifiable, Codable {
    let id: String?
    let title: String
    let description: String?
    let ingredients: [String]
    let steps: [String]
    let userId: String?
    
    // El backend devuelve esto como string en formato ISO o null
    // Para simplificar, lo manejaremos como String opcional, 
    // pero idealmente usaríamos Date con DateDecodingStrategy
    let createdAt: String? 

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
        case ingredients
        case steps
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
