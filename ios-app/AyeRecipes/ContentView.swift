//
//  ContentView.swift
//  AyeRecipes
//
//  Created by Jose Alberto Montero Martinez on 1/11/26.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var recipeService = RecipeService()
    
    var body: some View {
        TabView {

            CreateRecipeView()
                .tabItem {
                    Label("Crear", systemImage: "plus.circle.fill")
                }        
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            RecipesListView()
                .tabItem {
                    Label("Recetas", systemImage: "list.bullet")
                }
        }
        .tabViewStyle(.sidebarAdaptable)
        .environmentObject(recipeService)
        .tint(Color(red: 1.0, green: 0.27, blue: 0.0))
    }
}

#Preview {
    ContentView()
}
