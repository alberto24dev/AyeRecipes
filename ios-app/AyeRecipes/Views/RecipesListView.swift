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
            List(recipeService.recipes) { recipe in
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
            .navigationTitle("Mis Recetas")
            .overlay {
                if recipeService.recipes.isEmpty && !recipeService.isLoading {
                    ContentUnavailableView("No hay recetas", systemImage: "fork.knife", description: Text("Crea tu primera receta para verla aquí"))
                }
            }
        }
    }
}

#Preview {
    RecipesListView()
        .environmentObject(RecipeService())
}
