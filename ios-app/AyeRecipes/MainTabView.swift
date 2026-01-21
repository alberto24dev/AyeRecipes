import SwiftUI

struct MainTabView: View {
    // Tu servicio de recetas original
    @StateObject private var recipeService = RecipeService()
    
    // Agregamos esto para poder acceder a los datos del usuario o cerrar sesión
    @EnvironmentObject var authService: AuthService
    
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
        .onAppear {
            Task {
                await recipeService.fetchRecipes()
            }
        }
    }
}

#Preview {
    MainTabView()
}
