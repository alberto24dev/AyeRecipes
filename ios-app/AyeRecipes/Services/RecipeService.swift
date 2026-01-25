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

    private struct PresignedURLResponse: Codable {
        let uploadUrl: String
        let fileUrl: String
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
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Verificar status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    errorMessage = "Session expired. Please login again."
                    isLoading = false
                    return
                } else if !(200...299).contains(httpResponse.statusCode) {
                    errorMessage = "Error: HTTP \(httpResponse.statusCode)"
                    isLoading = false
                    return
                }
            }
            
            let decodedRecipes = try JSONDecoder().decode([Recipe].self, from: data)
            self.recipes = decodedRecipes
        } catch is CancellationError {
            // Ignorar errores de cancelación (pull to refresh puede ser cancelado)
            // Recipe fetch was cancelled
        } catch {
            // Error fetching recipes handled silently
            errorMessage = "Error loading recipes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    private func uploadImageToS3(imageData: Data, mimeType: String) async -> String? {
        struct PresignRequest: Codable {
            let fileName: String
            let contentType: String
        }

        let fileExtension = mimeType.contains("png") ? "png" : "jpg"
        let fileName = "recipe-" + UUID().uuidString + "." + fileExtension

        guard let presignURL = URL(string: "\(baseURL)/recipes/presigned-url") else {
            return nil
        }

        var request = URLRequest(url: presignURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let payload = PresignRequest(fileName: fileName, contentType: mimeType)
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                // Failed to get presigned URL handled silently
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data) {
                    // Error details logged internally
                }
                return nil
            }

            let presigned = try JSONDecoder().decode(PresignedURLResponse.self, from: data)
            guard let uploadURL = URL(string: presigned.uploadUrl) else { return nil }

            var putRequest = URLRequest(url: uploadURL)
            putRequest.httpMethod = "PUT"
            putRequest.httpBody = imageData
            putRequest.setValue(mimeType, forHTTPHeaderField: "Content-Type")

            let (_, putResponse) = try await URLSession.shared.data(for: putRequest)
            guard let putHttp = putResponse as? HTTPURLResponse, (200...299).contains(putHttp.statusCode) else {
                let statusCode = (putResponse as? HTTPURLResponse)?.statusCode ?? -1
                // Failed to upload to S3 handled silently
                return nil
            }

            return presigned.fileUrl
        } catch {
            // Error uploading image handled silently
            return nil
        }
    }
    
    func createRecipe(title: String, description: String, ingredients: [String], steps: [String], imageData: Data? = nil, imageMimeType: String? = nil) async -> Bool {
        guard let url = URL(string: "\(baseURL)/recipes") else { return false }
        
        var imageUrl: String? = nil
        if let imageData = imageData {
            let mimeType = imageMimeType ?? "image/jpeg"
            imageUrl = await uploadImageToS3(imageData: imageData, mimeType: mimeType)
            if imageUrl == nil {
                self.errorMessage = "Could not upload image"
                return false
            }
        }

        let newRecipe = Recipe(
            id: nil,
            title: title,
            description: description,
            ingredients: ingredients,
            steps: steps,
            imageUrl: imageUrl,
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
            // Error creating recipe handled silently
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
            // Error deleting recipe handled silently
            self.errorMessage = "Error deleting: \(error.localizedDescription)"
            return false
        }
    }
}
