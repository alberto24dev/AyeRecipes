import Foundation
import SwiftUI
import Combine

@MainActor
class RecipeService: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // URL base de la API.
    // Nota: Si usas simulador, 127.0.0.1 apunta al simulador mismo. 
    // Para acceder al Mac (backend), a menudo funciona localhost.
    private let baseURL = "https://print-enormous-liz-mutual.trycloudflare.com/api"
    
    func fetchRecipes() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/recipes") else {
            isLoading = false
            errorMessage = "URL inválida"
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedRecipes = try JSONDecoder().decode([Recipe].self, from: data)
            self.recipes = decodedRecipes
        } catch {
            print("Error fetching recipes: \(error)")
            self.errorMessage = "Error al cargar recetas: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createRecipe(title: String, description: String, ingredients: [String], steps: [String]) async -> Bool {
        guard let url = URL(string: "\(baseURL)/recipes") else { return false }
        
        let newRecipe = Recipe(
            id: nil,
            title: title,
            description: description,
            ingredients: ingredients,
            steps: steps,
            createdAt: nil
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(newRecipe)
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                // Refrescar la lista después de crear
                await fetchRecipes()
                return true
            } else {
                return false
            }
        } catch {
            print("Error creating recipe: \(error)")
            return false
        }
    }
}
