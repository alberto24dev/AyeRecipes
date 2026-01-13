//
//  HomeView.swift
//  AyeRecipes
//
//  Created by Jose Alberto Montero Martinez on 1/12/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var recipeService: RecipeService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Resumen de Recetas")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    if recipeService.isLoading && recipeService.recipes.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        // Carrusel de recetas destacadas (tomamos las primeras 5 como ejemplo)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(recipeService.recipes.prefix(5)) { recipe in
                                    RecipeSummaryCard(title: recipe.title)
                                }
                                
                                if recipeService.recipes.isEmpty {
                                    Text("No hay recetas aún")
                                        .foregroundStyle(.secondary)
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Text("Recientes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Lista de recetas recientes (tomamos las ultimas 3 o las primeras 3)
                    VStack(spacing: 16) {
                        ForEach(recipeService.recipes.prefix(3)) { recipe in
                            HStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Image(systemName: "fork.knife")
                                            .foregroundStyle(.white)
                                    }
                                VStack(alignment: .leading) {
                                    Text(recipe.title)
                                        .font(.subheadline)
                                        .bold()
                                    Text(recipe.description ?? "Sin descripción")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("AyeRecipes")
            .task {
                await recipeService.fetchRecipes()
            }
            .refreshable {
                await recipeService.fetchRecipes()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(RecipeService())
}
