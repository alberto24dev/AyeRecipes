import Foundation
import SwiftUI
import Combine

@MainActor
class RecipeService: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let baseURL = AyeRecipesAPI.baseURL
    
    private var authToken: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }
    
    func fetchRecipes() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/recipes") else {
            isLoading = false
            errorMessage = "Invalid URL"
            return
        }
        
        do {
            var request = URLRequest(url: url)
            if let token = authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let decodedRecipes = try JSONDecoder().decode([Recipe].self, from: data)
            self.recipes = decodedRecipes
        } catch {
            print("Error fetching recipes: \(error)")
            self.errorMessage = "Error loading recipes: \(error.localizedDescription)"
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
            userId: nil,
            createdAt: nil
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let jsonData = try JSONEncoder().encode(newRecipe)
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                self.successMessage = "Recipe created successfully"
                // Refrescar la lista después de crear
                await fetchRecipes()
                return true
            } else {
                self.errorMessage = "Could not save recipe"
                return false
            }
        } catch {
            print("Error creating recipe: \(error)")
            self.errorMessage = "Error creating recipe: \(error.localizedDescription)"
            return false
        }
    }
    
    func deleteRecipe(id: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/recipes/\(id)") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                // Remover localmente para actualización inmediata
                if let index = recipes.firstIndex(where: { $0.id == id }) {
                    recipes.remove(at: index)
                }
                return true
            } else {
                self.errorMessage = "Could not delete recipe"
                return false
            }
        } catch {
            print("Error deleting recipe: \(error)")
            self.errorMessage = "Error deleting: \(error.localizedDescription)"
            return false
        }
    }
}
