//
//  RecipesListView.swift
//  AyeRecipes
//
//  Created by Jose Alberto Montero Martinez on 1/12/26.
//

import SwiftUI

struct RecipesListView: View {
    @EnvironmentObject var recipeService: RecipeService
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(recipeService.recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            VStack(alignment: .leading) {
                                Text(recipe.title)
                                    .font(.headline)
                                if let description = recipe.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipe)
                }
                .navigationTitle("My Recipes")
                .overlay {
                    if recipeService.recipes.isEmpty && !recipeService.isLoading {
                        ContentUnavailableView("No recipes", systemImage: "fork.knife", description: Text("Create your first recipe to see it here"))
                    }
                }
                
                // Overlay de mensajes (Éxito o Error)
                if let message = recipeService.successMessage ?? recipeService.errorMessage {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    if recipeService.successMessage != nil {
                                        recipeService.successMessage = nil
                                    }
                                    if recipeService.errorMessage != nil {
                                        recipeService.errorMessage = nil
                                    }
                                }
                            }
                        }
                    
                    VStack(spacing: 16) {
                        Image(systemName: recipeService.successMessage != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(recipeService.successMessage != nil ? .green : .red)
                        
                        Text(recipeService.successMessage != nil ? "Saved!" : "Error")
                            .font(.headline)
                        
                        Text(message)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .frame(width: 200)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .onAppear {
                Task {
                    await recipeService.fetchRecipes()
                }
            }
        }
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        // Necesitamos obtener los IDs de las recetas que se van a eliminar
        // pero .onDelete nos da índices.
        
        // Hacemos una copia de los items a eliminar para procesarlos
        let recipesToDelete = offsets.map { recipeService.recipes[$0] }
        
        // Eliminamos de la lista localmente primero (optimista) o esperamos a la API
        // SwiftUI espera que actualicemos el modelo en el closure de onDelete usualmente,
        // o si es asíncrono, puede ser tricky.
        
        // Sin embargo, como tenemos RecipeService como ObservableObject y @Published recipes,
        // podemos llamar al servicio.
        
        Task {
            for recipe in recipesToDelete {
                if let id = recipe.id {
                    await recipeService.deleteRecipe(id: id)
                }
            }
        }
    }
}

#Preview {
    RecipesListView()
        .environmentObject(RecipeService())
}
