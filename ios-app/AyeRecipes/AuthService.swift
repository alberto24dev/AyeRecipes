import Foundation
import Combine

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var authToken: String?
    
    private let baseURL = AyeRecipesAPI.baseURL
    
    // Guardar token en UserDefaults
    private let tokenKey = "authToken"
    private let userKey = "currentUser"
    
    init() {
        // Limpiar datos residuales de sesiones anteriores (solo en desarrollo)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        
        loadSavedCredentials()
    }
    
    // MARK: - Login
    func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return false
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(loginRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Authentication error"
                isLoading = false
                return false
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            if loginResponse.success {
                self.authToken = loginResponse.token
                self.isAuthenticated = true
                self.successMessage = "Session started successfully!"
                
                if let user = loginResponse.user {
                    self.currentUser = User(
                        id: user["_id"] ?? user["id"] ?? "",
                        email: user["email"] ?? "",
                        name: user["name"] ?? ""
                    )
                }
                
                // Guardar token
                UserDefaults.standard.set(loginResponse.token, forKey: tokenKey)
                if let currentUser = self.currentUser {
                    UserDefaults.standard.set(try? JSONEncoder().encode(currentUser), forKey: userKey)
                }
                
                isLoading = false
                return true
            } else {
                errorMessage = loginResponse.message
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Connection error: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Register
    func register(email: String, password: String, name: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return false
        }
        
        let registerRequest = RegisterRequest(email: email, password: password, name: name)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(registerRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                let errorResponse = try? JSONDecoder().decode([String: String].self, from: data)
                errorMessage = errorResponse?["detail"] ?? "Registration error"
                isLoading = false
                return false
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            if loginResponse.success {
                self.authToken = loginResponse.token
                self.isAuthenticated = true
                self.successMessage = "Account created successfully!"
                
                if let user = loginResponse.user {
                    self.currentUser = User(
                        id: user["_id"] ?? user["id"] ?? "",
                        email: user["email"] ?? "",
                        name: user["name"] ?? ""
                    )
                }
                
                // Guardar token
                UserDefaults.standard.set(loginResponse.token, forKey: tokenKey)
                if let currentUser = self.currentUser {
                    UserDefaults.standard.set(try? JSONEncoder().encode(currentUser), forKey: userKey)
                }
                
                isLoading = false
                return true
            } else {
                errorMessage = loginResponse.message
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Connection error: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Logout
    func logout() {
        isAuthenticated = false
        currentUser = nil
        authToken = nil
        errorMessage = nil
        successMessage = nil
        
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
    
    // MARK: - Load Saved Credentials
    private func loadSavedCredentials() {
        if let savedToken = UserDefaults.standard.string(forKey: tokenKey),
           !savedToken.isEmpty {
            authToken = savedToken
            isAuthenticated = true
            
            if let userData = UserDefaults.standard.data(forKey: userKey),
               let user = try? JSONDecoder().decode(User.self, from: userData) {
                currentUser = user
            }
        } else {
            // Si no hay token válido, asegurarse de que no está autenticado
            isAuthenticated = false
            authToken = nil
            currentUser = nil
        }
    }
}

// MARK: - Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let user: [String: String]?
    let token: String?
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case name
    }
}
