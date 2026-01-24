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
                if recipeService.recipes.isEmpty && !recipeService.isLoading {
                    ScrollView {
                        VStack {
                            ContentUnavailableView("No recipes", systemImage: "fork.knife", description: Text("Create your first recipe to see it here"))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .navigationTitle("My Recipes")
                    .refreshable {
                        await recipeService.fetchRecipes()
                    }
                } else {
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
                    .refreshable {
                        await recipeService.fetchRecipes()
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
        let recipesToDelete = offsets.map { recipeService.recipes[$0] }
        Task {
            var anyError = false
            for recipe in recipesToDelete {
                if let id = recipe.id {
                    let success = await recipeService.deleteRecipe(id: id)
                    if !success { anyError = true }
                }
            }
            if anyError {
                recipeService.errorMessage = "One or more recipes could not be deleted."
            }
        }
    }
}

#Preview {
    RecipesListView()
        .environmentObject(RecipeService())
}
