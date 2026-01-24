//
//  HomeView.swift
//  AyeRecipes
//
//  Created by Jose Alberto Montero Martinez on 1/12/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var recipeService: RecipeService
    @State private var showOverlayMessage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recipes Summary")
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
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        RecipeSummaryCard(title: recipe.title, imageUrl: recipe.imageUrl)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if recipeService.recipes.isEmpty {
                                    Text("No recipes yet")
                                        .foregroundStyle(.secondary)
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Text("Recent")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Lista de recetas recientes (tomamos las ultimas 3 o las primeras 3)
                    VStack(spacing: 16) {
                        ForEach(recipeService.recipes.prefix(3)) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                HStack(spacing: 12) {
                                    RemoteImage(url: recipe.imageUrl)
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading) {
                                        Text(recipe.title)
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundStyle(.primary)
                                        Text(recipe.description ?? "No description")
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
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            
            // Overlay de mensajes (Éxito o Error)
            if showOverlayMessage, let message = recipeService.successMessage ?? recipeService.errorMessage {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showOverlayMessage = false
                                recipeService.successMessage = nil
                                recipeService.errorMessage = nil
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
            .navigationTitle("AyeRecipes")
            .task {
                await recipeService.fetchRecipes()
            }
            .refreshable {
                await recipeService.fetchRecipes()
            }
            .onChange(of: recipeService.successMessage) { _, newValue in
                if newValue != nil {
                    withAnimation {
                        showOverlayMessage = true
                    }
                }
            }
            .onChange(of: recipeService.errorMessage) { _, newValue in
                // Solo mostrar error en overlay si NO es un error de fetch normal
                if newValue != nil && !recipeService.isLoading {
                    withAnimation {
                        showOverlayMessage = true
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(RecipeService())
}
