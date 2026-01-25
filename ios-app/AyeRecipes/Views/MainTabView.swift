import SwiftUI

struct MainTabView: View {
    // Tu servicio de recetas original
    @StateObject private var recipeService = RecipeService()
    
    // Agregamos esto para poder acceder a los datos del usuario o cerrar sesión
    @EnvironmentObject var authService: AuthService
    
    @State private var hasLoadedRecipes = false
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            CreateRecipeView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
            
            RecipesListView()
                .tabItem {
                    Label("Recipes", systemImage: "list.bullet")
                }
        }
        .tabViewStyle(.sidebarAdaptable)
        .environmentObject(recipeService) // Pasamos el servicio de recetas
        .tint(Color(red: 1.0, green: 0.27, blue: 0.0))
        .task {
            // Cargar recetas de forma segura con manejo de errores
            // Se ejecuta después de que la UI esté completamente renderizada
            if !hasLoadedRecipes {
                do {
                    await recipeService.fetchRecipes()
                    hasLoadedRecipes = true
                } catch {
                    // Manejo silencioso - la UI mostrará un estado vacío o retry
                    // Error loading recipes handled silently
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
