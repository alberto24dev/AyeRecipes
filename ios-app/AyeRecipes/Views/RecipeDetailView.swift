
import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image
                if recipe.imageUrl != nil {
                    RemoteImage(url: recipe.imageUrl)
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipped()
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Title and Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.largeTitle)
                        .bold()
                    
                    if let description = recipe.description {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Ingredients
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients")
                        .font(.title2)
                        .bold()
                    
                    if recipe.ingredients.isEmpty {
                        Text("No ingredients registered")
                            .italic()
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .padding(.top, 8)
                                    .foregroundStyle(.orange)
                                Text(ingredient)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    Text("Steps")
                        .font(.title2)
                        .bold()
                    
                    if recipe.steps.isEmpty {
                        Text("No steps registered")
                            .italic()
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .bold()
                                    .foregroundStyle(.orange)
                                    .frame(width: 24, alignment: .leading)
                                
                                Text(step)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(
        id: "1",
        title: "Pasta Carbonara",
        description: "A delicious classic Italian pasta with egg, pecorino cheese, guanciale and black pepper.",
        ingredients: ["Spaghetti", "Eggs", "Pecorino Cheese", "Guanciale", "Black Pepper"],
        steps: ["Boil water", "Cook pasta", "Prepare sauce", "Mix everything"],
        imageUrl: nil,
        userId: "user1",
        createdAt: nil
    ))
}
