//
//  RecipesListView.swift
//  AyeRecipes
//
//  Versión Mejorada: Integra optimizaciones de lazy loading y mejor rendimiento
//  Combina funcionalidad de RecipesListView + OptimizedRecipesList
//
//  Created by Jose Alberto Montero Martinez on 1/12/26.
//

import SwiftUI

struct RecipesListView: View {
    @EnvironmentObject var recipeService: RecipeService
    @ObservedObject private var hapticManager = HapticManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                if recipeService.recipes.isEmpty && !recipeService.isLoading {
                    ScrollView {
                        VStack(spacing: 16) {
                            ContentUnavailableView("No recipes", systemImage: "fork.knife", description: Text("Create your first recipe to see it here"))
                            
                            NavigationLink(destination: CreateRecipeView()) {
                                Label("Create First Recipe", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .cornerRadius(8)
                                    .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .navigationTitle("My Recipes")
                    .refreshable {
                        await recipeService.fetchRecipes()
                    }
                } else {
                    List {
                        if recipeService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            ForEach(recipeService.recipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 12) {
                                            // Lazy load de imagen
                                            RemoteImage(url: recipe.imageUrl)
                                                .frame(width: 60, height: 60)
                                                .cornerRadius(6)
                                                .clipped()
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(recipe.title)
                                                    .font(.headline)
                                                    .lineLimit(1)
                                                
                                                if let description = recipe.description {
                                                    Text(description)
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .onDelete(perform: deleteRecipe)
                        }
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
            .task {
                if recipeService.recipes.isEmpty {
                    await recipeService.fetchRecipes()
                }
            }
        }
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        hapticManager.playSelection()
        let recipesToDelete = offsets.map { recipeService.recipes[$0] }
        Task {
            var anyError = false
            for recipe in recipesToDelete {
                if let id = recipe.id {
                    let success = await recipeService.deleteRecipe(id: id)
                    if !success {
                        anyError = true
                    } else {
                        hapticManager.playSuccess()
                    }
                }
            }
            if anyError {
                hapticManager.playError()
                recipeService.errorMessage = "One or more recipes could not be deleted."
            }
        }
    }
}

#Preview {
    RecipesListView()
        .environmentObject(RecipeService())
}
